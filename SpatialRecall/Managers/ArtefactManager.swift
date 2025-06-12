//
//  ArtefactManager.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 02.05.25.
//

import RealityKit
import SwiftUI
import struct PhotosUI.PhotosPickerItem
import AVKit
import ARKit
import Photos

@MainActor
class ArtefactManager: ObservableObject {
    static let shared = ArtefactManager()
    
    var worldTracking = WorldTrackingManager.shared
    var persistenceManager = PersistenceManager()
    
    @Published var artefacts: [Entity] = []
    @Published var artefactEntities: [AnchorEntity] = []
    @Published var persistentArtefacts: [PersistentArtefact] = []
    private var demoMode = true //To load default artefacts
    private var demoModeSetup = true //To get set the locations of the default artefacts and extract the json
    private var demoManager = DemoManager()
    
    
    @Published var isErasing = false //to check if should delete on click
    @Published var selectedImage: PhotosPickerItem? //for the image to be acceses from the window in the AddImage
    @Published var textToEditID: UInt64?
    @Published var selectedAudioURL: URL?
    @Published var selectedObjectURL: URL?
    @Published var selectedVideoURL: URL?
    
    private init(){
        Task{
            if(demoMode){
                persistenceManager.clearAllArtefacts()
                if(demoModeSetup){
                    loadInitialArtefacts()
                }else{
                    loadDemoPersistedArtefacts()                    
                }
            }else{
                loadPersistedArtefacts()
                print("load persistence")
            }
        }
    }
    
    func addArtefact(artefact: Entity, at: simd_float4x4, type: ArtefactType, data: ArtefactData) {
        
        artefact.components.set(InputTargetComponent(allowedInputTypes: .all))
        artefact.components.set(GroundingShadowComponent(castsShadow: true))
        artefact.generateCollisionShapes(recursive: true)
        let persistentID = UUID()
        artefact.components.set(PersistentIDComponent(persistentID: persistentID))
        
        let worldAnchor = WorldAnchor(originFromAnchorTransform: at)
        let anchor = AnchorEntity(world: at)
        Task{
            do{ try await worldTracking.worldInfo.addAnchor(worldAnchor) }catch{print("error adding anchor", error)}
            let persistentArtefact = PersistentArtefact(
                id: persistentID,
                worldAnchor: worldAnchor.id,
                type: type,
                data: data,
                position: artefact.position,
                orientation: CodableQuatf(from: artefact.orientation),
                scale: artefact.scale
            )
            persistentArtefacts.append(persistentArtefact)
            persistenceManager.saveArtefacts(persistentArtefacts)
            
            anchor.children.append(artefact)
            artefactEntities.append(anchor)
            artefacts.append(artefact)
        }
    }
    
    func removeArtefact(_ artefact: Entity) async {
        var artefact = artefact
        if artefact.name == "TextEntity" {
            if textToEditID == artefact.id {
                textToEditID = nil
            }
        }
        artefacts.removeAll(where: { $0 == artefact})
        if let persistentIDComponent = artefact.components[PersistentIDComponent.self]{
            if let persistentArtefact = persistentArtefacts.first(where: {$0.id == persistentIDComponent.persistentID}) {
                let data = persistentArtefact.data
                let id = data.imageAssetID != nil ? data.imageAssetID : data.videoID != nil ? data.videoID : data.objectID
                persistenceManager.deleteMedia(mediaID: id)
            }
            persistentArtefacts.removeAll(where: { $0.id == persistentIDComponent.persistentID})
            
        }
        if artefact.parent is AnchorEntity {
            artefact = artefact.parent!
        }
        artefactEntities.removeAll { $0 == artefact }
        savePersistentArtefacts()
    }
    
    func getHeadPositionAndMoveBy(_ offset: simd_float3) -> simd_float4x4? {
        // Get the current head position matrix
        guard let headTransform = getHeadWorldPositionAsMatrix() else { return nil }
        
        // For upright positioning, we only want horizontal rotation (yaw)
        // Extract only the Y rotation component
        let headYaw = atan2(headTransform.columns.2.x, headTransform.columns.2.z)
        
        // Create rotation matrix with only Y rotation
        let cosYaw = cos(headYaw)
        let sinYaw = sin(headYaw)
        let yRotationMatrix = simd_float3x3(
            simd_float3(cosYaw, 0, -sinYaw),
            simd_float3(0, 1, 0),
            simd_float3(sinYaw, 0, cosYaw)
        )
        
        // Transform the local offset to world space (only horizontal rotation)
        let worldOffset = yRotationMatrix * offset
        
        // Calculate the new position
        let headPosition = simd_float3(
            headTransform.columns.3.x,
            headTransform.columns.3.y,
            headTransform.columns.3.z
        )
        let newPosition = headPosition + worldOffset
        
        // Create upright transform (identity rotation) - no rotation towards user
        var uprightTransform = simd_float4x4(1.0)
        uprightTransform.columns.3 = simd_float4(newPosition.x, newPosition.y, newPosition.z, 1.0)
        
        return uprightTransform
    }
    
    func getOrientationFromMoveByMatrix(_ simd: simd_float4x4) -> simd_quatf? {
        guard let headTransform = getHeadWorldPositionAsMatrix() else { return nil }
        let headPosition = simd_float3(
            headTransform.columns.3.x,
            headTransform.columns.3.y,
            headTransform.columns.3.z
        )
        let newPosition = SIMD3(simd.columns.3.x, simd.columns.3.y, simd.columns.3.z)
        
        // Create transform that faces the head position
        let directionToHead = simd_normalize(headPosition - newPosition)
       
        // Calculate rotation to face the head (look-at rotation)
        let forward = directionToHead
        let worldUp = simd_float3(0, 1, 0)
        let right = simd_normalize(simd_cross(worldUp, forward))
        let up = simd_cross(forward, right)
        
        // Create the rotation matrix (3x3)
        let rotationMatrix3x3 = simd_float3x3(
            simd_float3(right.x, right.y, right.z),
            simd_float3(up.x, up.y, up.z),
            simd_float3(forward.x, forward.y, forward.z)
        )
        return simd_quatf(rotationMatrix3x3)
    }
    
    func repositionAllAnchors() async {
        
        for artefact in artefacts {
            guard let persistentIDComponent = artefact.components[PersistentIDComponent.self] else { return }
            guard let persistentArtefact = persistentArtefacts.first(where: {$0.id == persistentIDComponent.persistentID}) else { return }
            let worldAnchors = await worldTracking.worldInfo.allAnchors
            guard let worldAnchor = worldAnchors?.first(where: { $0.id == persistentArtefact.worldAnchor }) else { return }
            
            guard let transform = getHeadPositionAndMoveBy(simd_float3(0,0,-1.0)) else { return }
            guard let rotation = getOrientationFromMoveByMatrix(transform) else { return }
            
            artefact.setOrientation(rotation, relativeTo: nil)
            
            var anchor = AnchorEntity(world: transform)
            anchor = AnchorEntity(world: worldAnchor.originFromAnchorTransform)
            
            anchor.children.append(artefact)
            artefactEntities.removeAll { $0.id == artefact.parent?.id }
            artefactEntities.append(anchor)
        }
            
    }
    
    func getHeadWorldPositionAsMatrix() -> simd_float4x4? {
        return worldTracking.getHeadWorldPositionAsMatrix()
    }
    
    //Mark helper for saving
    private func modifyPersistentArtefacts() {
        for i in 0..<persistentArtefacts.count {
            guard let artefact = artefacts.first(where: { entity in
                guard let persistentIDComponent = entity.components[PersistentIDComponent.self] else { return false }
                return persistentArtefacts[i].id == persistentIDComponent.persistentID
            }) else { continue }
            
            persistentArtefacts[i].position = artefact.position
            persistentArtefacts[i].scale = artefact.scale
            persistentArtefacts[i].orientation = CodableQuatf(from: artefact.orientation)
            if artefact.name == "TextEntity"{
                for child in artefact.children {
                    if let tagComp = child.components[TagComponent.self],
                       tagComp.tag == "TextField" {
                        persistentArtefacts[i].data.textContent = child.name
                    }
                }
            }
        }
    }
    
    func savePersistentArtefacts() {
        modifyPersistentArtefacts()
        persistenceManager.saveArtefacts(persistentArtefacts)
    }
    
    
    private func loadPersistedArtefacts() {
        persistentArtefacts = persistenceManager.loadArtefacts()
        Task {
            await worldTracking.waitForSessionReady()
            await worldTracking.removeUnusedAnchors()
            await recreateArtefactsFromPersistence()
        }
        
    }
    
    private func loadDemoPersistedArtefacts() {
        persistentArtefacts = persistenceManager.loadDemoArtefacts()
        Task {
            await worldTracking.waitForSessionReady()
            await worldTracking.removeUnusedAnchors()
            await recreateDemo()
        }
    }
    
    private func recreateArtefactsFromPersistence() async {
        for persistentArtefact in persistentArtefacts {
            let data = persistentArtefact.data
            
            var entity: Entity?
            
            switch persistentArtefact.type {
            case .image:
                if let imageAssetID = data.imageAssetID {
                    entity = await createImageEntity(from: imageAssetID)
                }
            case .video:
                if let videoID = data.videoID {
                    entity = await createVideoEntity(from: videoID)
                }
            case .audio:
                if let audioURL = data.audioURL {
                    entity = await createAudioEntity(from: audioURL)
                }
            case .text:
                if let textContent = data.textContent {
                    entity = await createTextEntity(text: textContent)
                }
            case .object:
                if let objectID = data.objectID {
                    entity = await createObjectEntity(from: objectID)
                }
            }
            
            if let entity = entity {
                entity.components.set(InputTargetComponent(allowedInputTypes: .all))
                entity.components.set(GroundingShadowComponent(castsShadow: true))
                entity.components.set(PersistentIDComponent(persistentID: persistentArtefact.id))
                entity.generateCollisionShapes(recursive: true)
                
                guard let transform = getHeadPositionAndMoveBy(simd_float3(0,0,-1.0)) else { return }
                guard let rotation = getOrientationFromMoveByMatrix(transform) else { return }
                
                entity.setOrientation(rotation, relativeTo: nil)
                
                var anchor = AnchorEntity(world: transform)
                if let worldAnchor = await worldTracking.worldInfo.allAnchors?.first(where: {$0.id == persistentArtefact.worldAnchor}) {
                    anchor = AnchorEntity(world: worldAnchor.originFromAnchorTransform)
                }
                entity.position = persistentArtefact.position
                entity.scale = persistentArtefact.scale
                entity.orientation = persistentArtefact.orientation.simdQuat
                anchor.children.append(entity)
                
                await MainActor.run {
                    artefactEntities.append(anchor)
                    artefacts.append(entity)
                }
            }
        }
    }
    
    private func recreateDemo() async {
        for persistentArtefact in persistentArtefacts {
            
            let entity = await demoManager.getDemoEntity(type: persistentArtefact.type)
            
            
            if let entity = entity {
                guard let transform = getHeadPositionAndMoveBy(simd_float3(0,0,-1.0)) else { return }
                guard let rotation = getOrientationFromMoveByMatrix(transform) else { return }
                
                entity.setOrientation(rotation, relativeTo: nil)
                
                var anchor = AnchorEntity(world: transform)
                
                entity.components.set(InputTargetComponent(allowedInputTypes: .all))
                entity.components.set(GroundingShadowComponent(castsShadow: true))
                entity.components.set(PersistentIDComponent(persistentID: persistentArtefact.id))
                entity.generateCollisionShapes(recursive: true)
                
                if let worldAnchor = await worldTracking.worldInfo.allAnchors?.first(where: {$0.id == persistentArtefact.worldAnchor}) {
                    anchor = AnchorEntity(world: worldAnchor.originFromAnchorTransform)
                }
                entity.position = persistentArtefact.position
                entity.scale = persistentArtefact.scale
                entity.orientation = persistentArtefact.orientation.simdQuat
                anchor.children.append(entity)
                
                await MainActor.run {
                    artefactEntities.append(anchor)
                    artefacts.append(entity)
                }
            }
        }
    }
    
    func createTextEntity(text: String) async -> Entity? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return nil}
        
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.3, 0.3, 0.001))
        let material = SimpleMaterial(color: .yellow, roughness: 0.8 ,isMetallic: true)
        let box = ModelEntity(mesh: mesh, materials: [material])
        box.components.set(TagComponent(tag: "BackgroundBox"))
        
        let textEntity = generateTextEntity(text: trimmedText)
        textEntity.name = trimmedText
        textEntity.components.set(TagComponent(tag: "TextField"))
        
        let containerEntity = Entity()
        containerEntity.addChild(box)
        containerEntity.addChild(textEntity)
        
        centerTextAndBackground(textEntity: textEntity)
        
        containerEntity.name = "TextEntity"
        
        resizeBox(box: box, textEntity: textEntity)
        
        return containerEntity
    }
    
    
    func createAudioEntity(from url: URL) async -> Entity? {
        let mesh = MeshResource.generateSphere(radius: 0.1)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        let sphere = ModelEntity(mesh: mesh, materials: [material])
        
        sphere.name = "AudioEntity"
        sphere.components.set(AudioComponent(url: url))
        sphere.components.set(BillboardComponent())
        
        ArtefactGestures.updatePlayPauseIndicator(for: sphere, isPlaying: false)
        
        return sphere
    }
    
    func createImageEntity(from imageID: String, width: Float? = nil, height: Float? = nil) async -> Entity? {
        let uiImage = persistenceManager.loadImage(imageID: imageID)
        
        guard uiImage != nil else { return nil }
        let entity = Entity()
        
        // Use stored dimensions or calculate from image
        let imageWidth: Float
        let imageHeight: Float
        
        if let storedWidth = width, let storedHeight = height {
            imageWidth = storedWidth
            imageHeight = storedHeight
        } else {
            let proportionalWidth = Float(uiImage!.cgImage!.width) / Float(uiImage!.cgImage!.height)
            imageHeight = 0.3
            imageWidth = proportionalWidth * imageHeight
        }
        
        do {
            let texture = try await TextureResource(image: uiImage!.cgImage!, options: .init(semantic: .color))
            
            var frontMaterial = UnlitMaterial()
            frontMaterial.color = .init(tint: .white, texture: .init(texture))
            let mesh = MeshResource.generateBox(width: imageWidth, height: imageHeight, depth: 0.001, splitFaces: true)
            let restMaterial = SimpleMaterial(color: .black, isMetallic: false)
            
            let modelEntity = ModelEntity(mesh: mesh, materials: [frontMaterial, restMaterial, restMaterial, restMaterial, restMaterial, restMaterial])
            entity.addChild(modelEntity)
            
        } catch {
            print("Failed to create texture: \(error)")
            return nil
        }
        
        return entity
    }
    
    func createVideoEntity(from videoID: String) async -> Entity? {
        guard let url = persistenceManager.getVideoURL(videoID: videoID) else { return nil}
        guard let videoSize = await getVideoSize(url: url) else { return nil }
        let proportionalWidth:Float = Float(videoSize.width / videoSize.height)
        let videoHeight: Float = 0.3
        let avPlayer = AVPlayer(url: url)
        let videoMaterial = VideoMaterial(avPlayer: avPlayer)
        
        let mesh = MeshResource.generateBox(width: proportionalWidth*videoHeight, height: videoHeight, depth: 0.001, splitFaces: true)
        let restMaterial = SimpleMaterial(color: .black, isMetallic: false)
        let video = ModelEntity(mesh: mesh, materials: [videoMaterial,/*fron face*/ restMaterial, restMaterial, restMaterial, restMaterial, restMaterial /*other faces*/])
        video.name = "VideoEntity"
        video.components.set(VideoComponent(player: avPlayer, isPlaying: false))
        return video
    }
    
    func createObjectEntity(from id: String) async -> Entity? {
        // Request access to security-scoped resource
        guard let url = persistenceManager.getObjectURL(objectID: id) else { return nil }
        do {
            let modelEntity = try await ModelEntity(contentsOf: url)
            
            return modelEntity
        } catch {
            print("Failed to create ModelEntity: \(error)")
            return nil
        }
    }
    
    public func addText(text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        guard let transform = getHeadPositionAndMoveBy(simd_float3(0,0,-1.0)) else { return }
        
        
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.3, 0.3, 0.001))
        let material = SimpleMaterial(color: .yellow, roughness: 0.8 ,isMetallic: true)
        let box = ModelEntity(mesh: mesh, materials: [material])
        box.components.set(TagComponent(tag: "BackgroundBox"))
        
        let textEntity = generateTextEntity(text: trimmedText)
        textEntity.name = trimmedText
        textEntity.components.set(TagComponent(tag: "TextField"))
        
        let containerEntity = Entity()
        containerEntity.addChild(box)
        containerEntity.addChild(textEntity)
        
        guard let rotation = getOrientationFromMoveByMatrix(transform) else { return }
        
        containerEntity.setOrientation(rotation, relativeTo: nil)
        
        centerTextAndBackground(textEntity: textEntity)
        
        containerEntity.name = "TextEntity"
        
        resizeBox(box: box, textEntity: textEntity)
        
        addArtefact(artefact: containerEntity, at: transform, type: .text, data: ArtefactData(textContent: text))
    }
    
    public func addImage(data: Data) async {
        if let cgImage = UIImage(data: data)?.cgImage {
            let proportionalWidth = Float(cgImage.width) / Float(cgImage.height)
            
            let imageHeight: Float = 0.3
            
            guard let texture = try? await TextureResource(image: cgImage, options: .init(semantic: .color)) else {return}
            
            var frontMaterial = UnlitMaterial()
            frontMaterial.color = .init(tint: .white, texture: .init(texture))
            let mesh = MeshResource.generateBox(width: proportionalWidth*imageHeight, height: imageHeight, depth: 0.001, splitFaces: true)
            let restMaterial = SimpleMaterial(color: .black, isMetallic: false)
            let image = ModelEntity(mesh: mesh, materials: [frontMaterial,/*fron face*/ restMaterial, restMaterial, restMaterial, restMaterial, restMaterial /*other faces*/])
            
            
            guard let transform = getHeadPositionAndMoveBy(simd_float3(0,0,-1.0)) else { return }
            guard let rotation = getOrientationFromMoveByMatrix(transform) else { return }
            
            image.setOrientation(rotation, relativeTo: nil)
            let imageID = persistenceManager.saveImage(data: data)
            addArtefact(artefact: image, at: transform, type: .image, data: ArtefactData(imageAssetID: imageID))
            
            selectedImage = nil
        }
    }
    
    public func addObject(url: URL) async {
        // Request access to security-scoped resource
        var needsSecurityScopedAccess = false
        var didStartAccessing = false

        // Check if the file is outside the app sandbox (like from Files app)
        // Bundle resources are typically in the app's directory
        if !url.path.hasPrefix(Bundle.main.bundlePath) {
            needsSecurityScopedAccess = true
        }

        if needsSecurityScopedAccess {
            didStartAccessing = url.startAccessingSecurityScopedResource()
            if !didStartAccessing {
                print("Failed to access security-scoped resource")
                return
            }
        }

        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let modelEntity = try await ModelEntity(contentsOf: url)
            
            guard let transform = getHeadPositionAndMoveBy(simd_float3(0,0,-1.0)) else { return }
            guard let rotation = getOrientationFromMoveByMatrix(transform) else { return }
            
            modelEntity.setOrientation(rotation, relativeTo: nil)
            
            let objectID = persistenceManager.saveObject(from: url)
            addArtefact(artefact: modelEntity, at: transform, type: .object, data: ArtefactData(objectID: objectID))
            selectedObjectURL = nil
        } catch {
            print("Failed to create ModelEntity: \(error)")
        }
    }
    
    public func addVideo(url: URL) async {
        guard let videoSize = await getVideoSize(url: url) else { return }
        let proportionalWidth:Float = Float(videoSize.width / videoSize.height)
        let videoHeight: Float = 0.3
        let avPlayer = AVPlayer(url: url)
        
        let videoMaterial = VideoMaterial(avPlayer: avPlayer)
        
        let mesh = MeshResource.generateBox(width: proportionalWidth*videoHeight, height: videoHeight, depth: 0.001, splitFaces: true)
        let restMaterial = SimpleMaterial(color: .black, isMetallic: false)
        let video = ModelEntity(mesh: mesh, materials: [videoMaterial,/*fron face*/ restMaterial, restMaterial, restMaterial, restMaterial, restMaterial /*other faces*/])
        video.name = "VideoEntity"
        video.components.set(VideoComponent(player: avPlayer, isPlaying: false))
        
        guard let transform = getHeadPositionAndMoveBy(simd_float3(0,0,-1.0)) else { return }
        
        guard let rotation = getOrientationFromMoveByMatrix(transform) else { return }
        
        video.setOrientation(rotation, relativeTo: nil)
        
        let videoID = persistenceManager.saveVideo(from: url)
        
        addArtefact(artefact: video, at: transform, type: .video, data: ArtefactData(videoID: videoID))
        
        selectedVideoURL = nil
    }
    
    public func addAudio(url: URL) {
       print("Adding Audio", url.lastPathComponent)
        guard let transform = getHeadPositionAndMoveBy(simd_float3(0,0,-1.0)) else { return }

        let mesh = MeshResource.generateSphere(radius: 0.1)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        let sphere = ModelEntity(mesh: mesh, materials: [material])
        
        sphere.name = "AudioEntity"
        sphere.components.set(AudioComponent(url: url))
        sphere.components.set(BillboardComponent())
        
        ArtefactGestures.updatePlayPauseIndicator(for: sphere, isPlaying: false)
        
        selectedAudioURL = nil
        
        addArtefact(artefact: sphere, at: transform, type: .audio, data: ArtefactData(audioURL: url))
    }
    
    func loadInitialArtefacts() {
        print("Loading init for setup")
        Task{
            await worldTracking.waitForSessionReady()
            loadTextArtefact()
            loadImageArtefact()
            loadObjectArtefact()
            loadVideoArtefact()
            loadAudioArtefact()            
        }
    }

    
    func loadTextArtefact() {
        addText(text: "Example text artefact")
    }
    
    func loadImageArtefact() {
        Task {
            let data = UIImage(named: "garmisch-image")?.pngData()
            await addImage(data: data!)
        }
    }
    
    func loadObjectArtefact() {
        Task {
            guard let url = Bundle.main.url(forResource: "ring", withExtension: "stl") else {
                print( "File 'pancakes' not found" )
                return
            }
            await addObject(url: url)
        }
    }
    
    func loadVideoArtefact() {
        Task {
            guard let url = Bundle.main.url(forResource: "garmisch-walk", withExtension: "mov") else {
                print( "File 'garmisch-walk' not found" )
                return
            }
            await addVideo(url: url)
        }
    }
    
    func loadAudioArtefact() {
        Task {
            guard let url = Bundle.main.url(forResource: "morning-rain", withExtension: "mp3") else {
                print( "File 'morning-rain' not found" )
                return
            }
            addAudio(url: url)
        }
    }
    
}

struct PersistentIDComponent: Component {
    let persistentID: UUID
}

extension simd_float4 {
    var xyz: simd_float3 {
        return simd_float3(x, y, z)
    }
}
