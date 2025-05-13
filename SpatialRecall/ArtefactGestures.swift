//
//  ArtefactDragGesture.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 02.05.25.
//

import SwiftUI
import RealityKit

struct ArtefactGestures {
    static func createDragGesture(artefactManager: ArtefactManager) -> some Gesture {
        return DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                Task { @MainActor in
                    if(artefactManager.isErasing) {return}
                    let entity = value.entity
                    if checkIfIsArtefact(entity: entity, artefactManager: artefactManager) {
                        guard var artefact: Entity = getArtefactEntity(entity: entity, artefactManager: artefactManager) else {return}
                        if artefact.parent is AnchorEntity {
                            artefact = artefact.parent!
                        }
                        let newPosition = SIMD3<Float>(value.translation3D / 100.0)
                        artefact.position = newPosition
                    }
                }
            }
    }
    static func createRemoveOnTapGesture(artefactManager: ArtefactManager) -> some Gesture {
        return  TapGesture()
            .targetedToAnyEntity()
            .onEnded{ value in
                Task{ @MainActor in
                    if(!artefactManager.isErasing) {return}
                    let entity = value.entity
                    if checkIfIsArtefact(entity: entity, artefactManager: artefactManager) {
                        guard var artefact: Entity = getArtefactEntity(entity: entity, artefactManager: artefactManager) else {return}
                        artefactManager.artefacts.removeAll(where: { $0 == entity})
                        if artefact.parent is AnchorEntity {
                            artefact = artefact.parent!
                        }
                        artefactManager.artefactEntities.removeAll { $0 == artefact }
                        
                    }
                }
            }
    }
    static func createPlayAudioGesture(artefactManager: ArtefactManager) -> some Gesture {
        return  TapGesture()
            .targetedToAnyEntity()
            .onEnded{ value in
                Task{ @MainActor in
                    if(artefactManager.isErasing) {return}
                    let entity = value.entity
                    if checkIfIsArtefact(entity: entity, artefactManager: artefactManager) {
                        guard let artefact: Entity = getArtefactEntity(entity: entity, artefactManager: artefactManager) else {return}
                        if(artefact.name != "AudioEntity") {return}
                        
                        if let audioComponent = artefact.components[AudioComponent.self] {
                            var isPlaying = false
                            if let playBack = audioComponent.playbackController {
                                if playBack.isPlaying {
                                    playBack.pause()
                                }else{
                                    isPlaying = true
                                    playBack.play()
                                }
                            }else {
                                guard let resource = try? AudioFileResource.load(contentsOf: audioComponent.url) else{print("smth went wrong"); return}
                                artefact.components.set(AudioComponent(url: audioComponent.url, playbackController: artefact.playAudio(resource)))
                                isPlaying = true
                            }
                            updatePlayPauseIndicator(for: artefact, isPlaying: isPlaying)
                            
                        }
                        
                    }
                }
            }
    }
    static func createPlayVideoGesture(artefactManager: ArtefactManager) -> some Gesture {
        return  TapGesture()
            .targetedToAnyEntity()
            .onEnded{ value in
                Task{ @MainActor in
                    if(artefactManager.isErasing) {return}
                    let entity = value.entity
                    if checkIfIsArtefact(entity: entity, artefactManager: artefactManager) {
                        guard let artefact: Entity = getArtefactEntity(entity: entity, artefactManager: artefactManager) else {return}
                        if(artefact.name != "VideoEntity") {return}
                        
                        if let videoComponent = artefact.components[VideoComponent.self] {
                            var isPlaying = videoComponent.isPlaying
                            if  videoComponent.player.currentTime() >= videoComponent.player.currentItem?.duration ?? .zero {
                                videoComponent.player.seek(to: .zero)
                                isPlaying = false
                            }
                            if !isPlaying {
                                videoComponent.player.play()
                                isPlaying = true
                            }else if isPlaying {
                                videoComponent.player.pause()
                                isPlaying = false
                            }
                            artefact.components[VideoComponent.self] = VideoComponent(player: videoComponent.player, isPlaying: isPlaying)
                        }
                        
                    }
                }
            }
    }
    
    static func updatePlayPauseIndicator(for entity: Entity, isPlaying: Bool) {
        // Remove existing indicator if any
        entity.children.removeAll(where: { $0.name == "PlayIndicator" || $0.name == "PauseIndicator" })

        let indicator: ModelEntity
        let material = SimpleMaterial(color: .white, roughness: 0.2, isMetallic: false)
        if isPlaying {
            // Pause icon: two rectangles
            let leftBar = ModelEntity(mesh: .generateBox(size: [0.02, 0.08, 0.01]), materials: [material])
            leftBar.position.x = -0.015
            let rightBar = ModelEntity(mesh: .generateBox(size: [0.02, 0.08, 0.01]), materials: [material])
            rightBar.position.x = 0.015
            indicator = ModelEntity()
            indicator.name = "PauseIndicator"
            indicator.addChild(leftBar)
            indicator.addChild(rightBar)
        } else {
            var descriptor = MeshDescriptor(name: "triangle")
               // Triangle vertices
            descriptor.positions = MeshBuffers.Positions([
                SIMD3<Float>(-0.02, -0.05, 0.0), // bottom-left
                SIMD3<Float>( 0.05,  0.0,  0.0), // right
                SIMD3<Float>(-0.02,  0.05, 0.0)  // top-left
            ])
           
            // Triangle face index
            descriptor.primitives = .triangles([0, 1, 2])
           
            let mesh = try! MeshResource.generate(from: [descriptor])// Replace with triangle mesh for real play icon
            indicator = ModelEntity(mesh: mesh, materials: [material])
            indicator.name = "PlayIndicator"
        }
        indicator.position = [0, 0, 0.11]
        entity.addChild(indicator)
    }

    
    static func createEditTextGesture(artefactManager: ArtefactManager, appModel: AppModel, openWindow: OpenWindowAction) -> some Gesture {
        return TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                Task { @MainActor in
                    if !artefactManager.isErasing {
                        let entity = value.entity
                        if checkIfIsArtefact(entity: entity, artefactManager: artefactManager) {
                            guard let artefact: Entity = getArtefactEntity(entity: entity, artefactManager: artefactManager) else {return}
                            guard artefact.name == "TextEntity" else {return}
                            artefactManager.textToEditID = artefact.id
                            openWindow(id: appModel.textEditorWindowID)
                        }
                    }
                }
            }
    }
    @MainActor
    private static func checkIfIsArtefact(entity: Entity, artefactManager: ArtefactManager) -> Bool {
        if artefactManager.artefacts.contains(entity){return true}
        else if artefactManager.artefacts.contains(entity.parent ?? Entity()) {return true}
        
        return false
    }
    @MainActor
    private static func getArtefactEntity(entity: Entity, artefactManager: ArtefactManager) -> Entity? {
        if let artefact: Entity = artefactManager.artefacts.first(where: { $0 == entity }) {
            return artefact
        }
        else if let artefact: Entity = artefactManager.artefacts.first(where: { $0 == entity.parent }) {
            return artefact
        }
        return nil
    }
}

extension RealityView {
    func installGestures(artefactManager: ArtefactManager, appModel: AppModel, openWindow: OpenWindowAction) -> some View {
        simultaneousGesture(ArtefactGestures.createDragGesture(artefactManager: artefactManager))
            .simultaneousGesture(ArtefactGestures.createRemoveOnTapGesture(artefactManager: artefactManager))
            .simultaneousGesture(ArtefactGestures.createEditTextGesture(artefactManager: artefactManager, appModel: appModel, openWindow: openWindow))
            .simultaneousGesture(ArtefactGestures.createPlayAudioGesture(artefactManager: artefactManager))
            .simultaneousGesture(ArtefactGestures.createPlayVideoGesture(artefactManager: artefactManager))
    }
}
