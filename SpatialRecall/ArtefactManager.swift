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

@MainActor
class ArtefactManager: ObservableObject {
    static let shared = ArtefactManager()
    @Published var artefacts: [Entity] = []
    @Published var artefactEntities: [Entity] = []
    
    @Published var isErasing = false //to check if should delete on click
    @Published var selectedImage: PhotosPickerItem? //for the image to be acceses from the window in the AddImage
    @Published var textToEditID: UInt64?
    @Published var selectedAudioURL: URL?
    @Published var selectedObjectURL: URL?
    @Published var selectedVideoURL: URL?
    
    func addArtefact(artefact: Entity, anchor: AnchorEntity) {
        
        artefact.components.set(InputTargetComponent(allowedInputTypes: .all))
        artefact.components.set(GroundingShadowComponent(castsShadow: true))
        artefact.generateCollisionShapes(recursive: true)
        artefact.position = .zero
        
        anchor.children.append(artefact)
        
        artefactEntities.append(anchor)
        artefacts.append(artefact)
    }
    
    public func addText(text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let anchor = AnchorEntity(.head)
        anchor.anchoring.trackingMode = .once
        anchor.position = SIMD3<Float>(0,0,-0.5)
        
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
        addArtefact(artefact: containerEntity ,anchor: anchor)
    }
    
    public func addImage(data: Data) async {
        let cgImage = UIImage(data: data)?.cgImage
        if let cgImage {
            let proportionalWidth = Float(cgImage.width) / Float(cgImage.height)
            
            let imageHeight: Float = 0.3
            
            guard let texture = try? await TextureResource(image: cgImage, options: .init(semantic: .color)) else {return}
            
            var frontMaterial = UnlitMaterial()
            frontMaterial.color = .init(tint: .white, texture: .init(texture))
            let mesh = MeshResource.generateBox(width: proportionalWidth*imageHeight, height: imageHeight, depth: 0.001, splitFaces: true)
            let restMaterial = SimpleMaterial(color: .black, isMetallic: false)
            let image = ModelEntity(mesh: mesh, materials: [frontMaterial,/*fron face*/ restMaterial, restMaterial, restMaterial, restMaterial, restMaterial /*other faces*/])
            
            
            let anchor = AnchorEntity(.head)
            anchor.anchoring.trackingMode = .once
            anchor.position = SIMD3<Float>(0,0,-1)
            
            addArtefact(artefact: image, anchor: anchor)
            
            selectedImage = nil
        }
    }
    
    public func addObject(url: URL) async {
        // Request access to security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource")
            return
        }
        
        defer {
            // Always stop accessing when done
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let modelEntity = try await ModelEntity(contentsOf: url)
            let anchor = AnchorEntity(.head)
            anchor.anchoring.trackingMode = .once
            anchor.position = SIMD3<Float>(0, 0, -1)
            anchor.addChild(modelEntity)
            addArtefact(artefact: modelEntity, anchor: anchor)
            selectedObjectURL = nil
        } catch {
            print("Failed to create ModelEntity: \(error)")
        }
    }
    
    public func addVideo(url: URL) async {
        guard let videoSize = await getVideoSize(url: url) else { return }
        let proportionalWidth:Float = Float(videoSize.width / videoSize.height)
        let videoHeight: Float = 0.3
        print(proportionalWidth)
        let avPlayer = AVPlayer(url: url)
        
        let videoMaterial = VideoMaterial(avPlayer: avPlayer)
        
        let mesh = MeshResource.generateBox(width: proportionalWidth*videoHeight, height: videoHeight, depth: 0.001, splitFaces: true)
        let restMaterial = SimpleMaterial(color: .black, isMetallic: false)
        let video = ModelEntity(mesh: mesh, materials: [videoMaterial,/*fron face*/ restMaterial, restMaterial, restMaterial, restMaterial, restMaterial /*other faces*/])
        video.name = "VideoEntity"
        video.components.set(VideoComponent(player: avPlayer, isPlaying: false))
        
        let anchor = AnchorEntity(.head)
        anchor.anchoring.trackingMode = .once
        anchor.position = SIMD3<Float>(0, 0, -1)
        anchor.addChild(video)
        
        addArtefact(artefact: video, anchor: anchor)
        
        selectedVideoURL = nil
    }
    
    public func addAudio(url: URL) {
        print("Adding Audio", url.lastPathComponent)
        let anchor = AnchorEntity(.head)
        anchor.anchoring.trackingMode = .once
        anchor.position = SIMD3<Float>(0, 0, -1)

        let mesh = MeshResource.generateSphere(radius: 0.1)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        let sphere = ModelEntity(mesh: mesh, materials: [material])
        
        sphere.name = "AudioEntity"
        sphere.components.set(AudioComponent(url: url))
        sphere.components.set(BillboardComponent())
        
        ArtefactGestures.updatePlayPauseIndicator(for: sphere, isPlaying: false)
        
        selectedAudioURL = nil
        
        addArtefact(artefact: sphere, anchor: anchor)
    }
}
