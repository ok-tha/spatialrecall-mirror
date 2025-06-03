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
            print(type, at)
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
    
    func repositionAllAnchors() async {
        
        for artefact in artefacts {
            guard let persistentIDComponent = artefact.components[PersistentIDComponent.self] else { return }
            guard let persistentArtefact = persistentArtefacts.first(where: {$0.id == persistentIDComponent.persistentID}) else { return }
            let worldAnchors = await worldTracking.worldInfo.allAnchors
            guard let worldAnchor = worldAnchors?.first(where: { $0.id == persistentArtefact.worldAnchor }) else { return }
            
            guard var headTransform = getHeadWorldPositionAsMatrix() else { return }
            let worldTransform = headTransform * SIMD4<Float>(0,0,-1,0)
            headTransform.columns.3.x += worldTransform.x
            headTransform.columns.3.z += worldTransform.z
            
            var anchor = AnchorEntity(world: headTransform)
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
                
                guard var headTransform = getHeadWorldPositionAsMatrix() else { return }
                let worldTransform = headTransform * SIMD4<Float>(0,0,-1,0)
                headTransform.columns.3.x += worldTransform.x
                headTransform.columns.3.z += worldTransform.z
                
                var anchor = AnchorEntity(world: headTransform)
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
            let data = persistentArtefact.data
            
            var entity = await demoManager.getDemoEntity(type: persistentArtefact.type)
            
            
            if let entity = entity {
                guard var headTransform = getHeadWorldPositionAsMatrix() else { return }
                let worldTransform = headTransform * SIMD4<Float>(0,0,-1,0)
                headTransform.columns.3.x += worldTransform.x
                headTransform.columns.3.z += worldTransform.z
                
                entity.components.set(InputTargetComponent(allowedInputTypes: .all))
                entity.components.set(GroundingShadowComponent(castsShadow: true))
                entity.components.set(PersistentIDComponent(persistentID: persistentArtefact.id))
                entity.generateCollisionShapes(recursive: true)
                
                var anchor = AnchorEntity(world: headTransform)
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
        
        guard var headTransform = getHeadWorldPositionAsMatrix() else { return }
        let worldTransform = headTransform * SIMD4<Float>(0,0,-1,0)
        headTransform.columns.3.x += worldTransform.x
        headTransform.columns.3.z += worldTransform.z
        
        
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
        
        addArtefact(artefact: containerEntity, at: headTransform, type: .text, data: ArtefactData(textContent: text))
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
            
            
            guard var headTransform = getHeadWorldPositionAsMatrix() else { return }
            let worldTransform = headTransform * SIMD4<Float>(0,0,-1,0)
            headTransform.columns.3.x += worldTransform.x
            headTransform.columns.3.z += worldTransform.z
            let imageID = persistenceManager.saveImage(data: data)
            addArtefact(artefact: image, at: headTransform, type: .image, data: ArtefactData(imageAssetID: imageID))
            
            selectedImage = nil
        }
    }
    
    public func addObject(url: URL) async {
        print(url)
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
        print("object", url)
        
        do {
            let modelEntity = try await ModelEntity(contentsOf: url)
            
            guard var headTransform = getHeadWorldPositionAsMatrix() else { return }
            let worldTransform = headTransform * SIMD4<Float>(0,0,-1,0)
            headTransform.columns.3.x += worldTransform.x
            headTransform.columns.3.z += worldTransform.z
            
            let objectID = persistenceManager.saveObject(from: url)
            addArtefact(artefact: modelEntity, at: headTransform, type: .object, data: ArtefactData(objectID: objectID))
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
        
        guard var headTransform = getHeadWorldPositionAsMatrix() else { return }
        let worldTransform = headTransform * SIMD4<Float>(0,0,-1,0)
        headTransform.columns.3.x += worldTransform.x
        headTransform.columns.3.z += worldTransform.z
        
        let videoID = persistenceManager.saveVideo(from: url)
        
        addArtefact(artefact: video, at: headTransform, type: .video, data: ArtefactData(videoID: videoID))
        
        selectedVideoURL = nil
    }
    
    public func addAudio(url: URL) {
       print("Adding Audio", url.lastPathComponent)
        guard var headTransform = getHeadWorldPositionAsMatrix() else { return }
        let worldTransform = headTransform * SIMD4<Float>(0,0,-1,0)
        headTransform.columns.3.x += worldTransform.x
        headTransform.columns.3.z += worldTransform.z

        let mesh = MeshResource.generateSphere(radius: 0.1)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        let sphere = ModelEntity(mesh: mesh, materials: [material])
        
        sphere.name = "AudioEntity"
        sphere.components.set(AudioComponent(url: url))
        sphere.components.set(BillboardComponent())
        
        ArtefactGestures.updatePlayPauseIndicator(for: sphere, isPlaying: false)
        
        selectedAudioURL = nil
        
        addArtefact(artefact: sphere, at: headTransform, type: .audio, data: ArtefactData(audioURL: url))
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
