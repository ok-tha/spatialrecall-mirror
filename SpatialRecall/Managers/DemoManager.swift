//
//  DemoManager.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 03.06.25.
//

import RealityKit
import SwiftUI
import AVKit

@MainActor
class DemoManager {
    func getDemoEntity(type: ArtefactType) async -> Entity? {
        var entity: Entity?
        switch type {
        case .image:
            entity = await createImageEntity()
        case .video:
            entity = await createVideoEntity()
        case .audio:
            entity = await createAudioEntity()
        case .text:
            entity = await createTextEntity(text: "Some Example Text")
        case .object:
            entity = await createObjectEntity()
        }
        return entity
    }

    func createTextEntity(text: String) async -> Entity? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return nil }

        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.3, 0.3, 0.001))
        let material = SimpleMaterial(
            color: .yellow,
            roughness: 0.8,
            isMetallic: true
        )
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

    func createAudioEntity() async -> Entity? {
        guard
            let url = Bundle.main.url(
                forResource: "garmisch-walk",
                withExtension: "mov"
            )
        else {
            print("File 'garmisch-walk' not found")
            return nil
        }

        let mesh = MeshResource.generateSphere(radius: 0.1)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        let sphere = ModelEntity(mesh: mesh, materials: [material])

        sphere.name = "AudioEntity"
        sphere.components.set(AudioComponent(url: url))
        sphere.components.set(BillboardComponent())

        ArtefactGestures.updatePlayPauseIndicator(for: sphere, isPlaying: false)

        return sphere
    }

    func createImageEntity() async -> Entity? {
        let uiImage = UIImage(named: "garmisch-image")

        guard uiImage != nil else { return nil }
        let entity = Entity()

        // Use stored dimensions or calculate from image
        let imageWidth: Float
        let imageHeight: Float

        let proportionalWidth =
            Float(uiImage!.cgImage!.width) / Float(uiImage!.cgImage!.height)
        imageHeight = 0.3
        imageWidth = proportionalWidth * imageHeight

        do {
            let texture = try await TextureResource(
                image: uiImage!.cgImage!,
                options: .init(semantic: .color)
            )

            var frontMaterial = UnlitMaterial()
            frontMaterial.color = .init(tint: .white, texture: .init(texture))
            let mesh = MeshResource.generateBox(
                width: imageWidth,
                height: imageHeight,
                depth: 0.001,
                splitFaces: true
            )
            let restMaterial = SimpleMaterial(color: .black, isMetallic: false)

            let modelEntity = ModelEntity(
                mesh: mesh,
                materials: [
                    frontMaterial, restMaterial, restMaterial, restMaterial,
                    restMaterial, restMaterial,
                ]
            )
            entity.addChild(modelEntity)

        } catch {
            print("Failed to create texture: \(error)")
            return nil
        }

        return entity
    }

    func createVideoEntity() async -> Entity? {
        guard
            let url = Bundle.main.url(
                forResource: "garmisch-walk",
                withExtension: "mov"
            )
        else {
            print("File 'garmisch-walk' not found")
            return nil
        }
        guard let videoSize = await getVideoSize(url: url) else { return nil }
        let proportionalWidth: Float = Float(videoSize.width / videoSize.height)
        let videoHeight: Float = 0.3
        let avPlayer = AVPlayer(url: url)
        let videoMaterial = VideoMaterial(avPlayer: avPlayer)

        let mesh = MeshResource.generateBox(
            width: proportionalWidth * videoHeight,
            height: videoHeight,
            depth: 0.001,
            splitFaces: true
        )
        let restMaterial = SimpleMaterial(color: .black, isMetallic: false)
        let video = ModelEntity(
            mesh: mesh,
            materials: [
                videoMaterial, /*fron face*/ restMaterial, restMaterial,
                restMaterial, restMaterial, restMaterial /*other faces*/,
            ]
        )
        video.name = "VideoEntity"
        video.components.set(VideoComponent(player: avPlayer, isPlaying: false))
        return video
    }

    func createObjectEntity() async -> Entity? {
        // Request access to security-scoped resource
        guard
            let url = Bundle.main.url(forResource: "ring", withExtension: "stl")
        else {
            print("File 'pancakes' not found")
            return nil
        }
        do {
            let modelEntity = try await ModelEntity(contentsOf: url)

            return modelEntity
        } catch {
            print("Failed to create ModelEntity: \(error)")
            return nil
        }
    }
}
