//
//  ArtefactDragGesture.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 02.05.25.
//

import SwiftUI
import RealityKit

struct ArtefactGestures {
    // MARK: - Gesture State
    private static var currentDragEntity: Entity? // Can be used to check if isDragging (!= nil). If problems appear, maybe use a dictionary [:] instead.
    private static var startPosition: SIMD3<Float> = .zero
    private static var isRotating: Bool = false
    private static var startOrientation: Rotation3D?
    private static var isScaling: Bool = false
    private static var startScale: SIMD3<Float> = .one
    
    // MARK: - Drag Gesture
    static func createDragGesture(artefactManager: ArtefactManager) -> some Gesture {
        return DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                Task { @MainActor in
                    guard !artefactManager.isErasing else { return }
                    guard let artefact = getValidArtefact(from: value.entity, artefactManager: artefactManager) else { return }
                                                                
                    // Set initial position only once per drag session
                    if currentDragEntity == nil || currentDragEntity !== artefact {
                        currentDragEntity = artefact
                        startPosition = artefact.position
                    }
                
                    let movement = value.convert(value.translation3D, from: .local, to: artefact.parent ?? artefact)
                    artefact.position = startPosition + movement
                }
            }
            .onEnded({ _ in
                currentDragEntity = nil
                startPosition = .zero
                Task{
                    await artefactManager.savePersistentArtefacts()
                }
            })
    }

    // MARK: - Rotate Gesture
    static func createRotateGesture(artefactManager: ArtefactManager) -> some Gesture {
        return RotateGesture3D()
            .targetedToAnyEntity()
            .onChanged { value in
                Task { @MainActor in
                    guard !artefactManager.isErasing else { return }
                    guard let artefact = getValidArtefact(from: value.entity, artefactManager: artefactManager) else { return }
                                        
                    if !isRotating {
                        isRotating = true
                        startOrientation = .init(artefact.orientation(relativeTo: nil))
                    }
                    
                    let rotation = value.rotation
                    let flippedRotation = Rotation3D(
                        angle: rotation.angle,
                        axis: RotationAxis3D(
                            x: -rotation.axis.x,
                            y: rotation.axis.y,
                            z: -rotation.axis.z
                        )
                    )
                    
                    let newOrientation = startOrientation!.rotated(by: flippedRotation)
                    artefact.setOrientation(.init(newOrientation), relativeTo: nil)
                }
            }
            .onEnded({ _ in
                isRotating = false;
                startOrientation = .identity
                Task{
                    await artefactManager.savePersistentArtefacts()
                }
            })
    }
    
    // MARK: - Magnify Gesture
    static func createMagnifyGesture(artefactManager: ArtefactManager) -> some Gesture {
        return MagnifyGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                Task { @MainActor in
                    guard !artefactManager.isErasing else { return }
                    guard let artefact = getValidArtefact(from: value.entity, artefactManager: artefactManager) else { return }
                                        
                    if !isScaling {
                        isScaling = true
                        startScale = artefact.scale
                    }
                    
                    let magnification = Float(value.magnification)
                    // let clampedMagnification = max(0.1, min(3.0, magnification)) // Limit between 10% and 300%
                    artefact.scale = startScale * magnification
                }
            }
            .onEnded({ _ in
                isScaling = false;
                startScale = SIMD3<Float>.one
                Task{
                    await artefactManager.savePersistentArtefacts()
                }
            })
    }
    
    // MARK: - Remove-on-tap Gesture
    static func createRemoveOnTapGesture(artefactManager: ArtefactManager) -> some Gesture {
        return TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                Task{ @MainActor in
                    guard artefactManager.isErasing else { return }
                    let entity = value.entity
                    guard let artefact = getValidArtefact(from: entity, artefactManager: artefactManager) else { return }
                    await artefactManager.removeArtefact(artefact)
                }
            }
    }
    
    // MARK: - Play-audio Gesture
    static func createPlayAudioGesture(artefactManager: ArtefactManager) -> some Gesture {
        return TapGesture()
            .targetedToAnyEntity()
            .onEnded{ value in
                Task{ @MainActor in
                    guard !artefactManager.isErasing else { return }
                    guard let artefact = getValidArtefact(from: value.entity, artefactManager: artefactManager),
                          artefact.name == "AudioEntity"
                    else { return }
                    
                    if let audioComponent = artefact.components[PlayerComponent.self] {
                        if !audioComponent.hasAddedEndObserver {
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: audioComponent.player.currentItem,
                                queue: .main
                            ) { _ in
                                updatePlayPauseIndicator(for: artefact, isPlaying: false)
                            }
                        }
                        var isPlaying = audioComponent.isPlaying
                        if  audioComponent.player.currentTime() >= audioComponent.player.currentItem?.duration ?? .zero {
                            audioComponent.player.seek(to: .zero)
                            isPlaying = false
                        }
                        if !isPlaying {
                            audioComponent.player.play()
                            isPlaying = true
                        } else if isPlaying {
                            audioComponent.player.pause()
                            isPlaying = false
                        }
                        artefact.components[PlayerComponent.self] = PlayerComponent(player: audioComponent.player, isPlaying: isPlaying, hasAddedEndObserver: true)
                        updatePlayPauseIndicator(for: artefact, isPlaying: isPlaying)
                    }
                }
            }
    }
    
    // MARK: - Create-video Gesture
    static func createPlayVideoGesture(artefactManager: ArtefactManager) -> some Gesture {
        return TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                Task { @MainActor in
                    guard !artefactManager.isErasing else { return }
                    guard let artefact = getValidArtefact(from: value.entity, artefactManager: artefactManager) else { return }
                        
                    if (artefact.name != "VideoEntity") {return}
                    
                    if let videoComponent = artefact.components[PlayerComponent.self] {
                        if !videoComponent.hasAddedEndObserver {
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: videoComponent.player.currentItem,
                                queue: .main
                            ) { _ in
                                updatePlayPauseIndicator(for: artefact, isPlaying: false, video: true)
                            }
                        }
                        var isPlaying = videoComponent.isPlaying
                        if  videoComponent.player.currentTime() >= videoComponent.player.currentItem?.duration ?? .zero {
                            videoComponent.player.seek(to: .zero)
                            isPlaying = false
                        }
                        if !isPlaying {
                            videoComponent.player.play()
                            isPlaying = true
                        } else if isPlaying {
                            videoComponent.player.pause()
                            isPlaying = false
                        }
                        artefact.components[PlayerComponent.self] = PlayerComponent(player: videoComponent.player, isPlaying: isPlaying, hasAddedEndObserver: true)
                        updatePlayPauseIndicator(for: artefact, isPlaying: isPlaying, video: true)
                    }
                }
            }
    }

    static func updatePlayPauseIndicator(for entity: Entity, isPlaying: Bool, video: Bool = false) {
        // Remove any existing indicators and backgrounds
        entity.children.removeAll(where: { $0.name.contains("Indicator") == true })

        // Build the indicator icon
        let indicator = ModelEntity()
        let material = SimpleMaterial(color: .white, roughness: 0.2, isMetallic: false)
        if isPlaying {
            let leftBar = ModelEntity(mesh: .generateBox(size: [0.02, 0.08, 0.01]), materials: [material])
            leftBar.position.x = -0.015
            let rightBar = ModelEntity(mesh: .generateBox(size: [0.02, 0.08, 0.01]), materials: [material])
            rightBar.position.x = 0.015
            indicator.name = "PauseIndicator"
            indicator.addChild(leftBar)
            indicator.addChild(rightBar)
        } else {
            var desc = MeshDescriptor(name: "triangle")
            desc.positions = MeshBuffers.Positions([
                SIMD3(-0.02, -0.05, 0),
                SIMD3(0.05, 0, 0),
                SIMD3(-0.02, 0.05, 0)
            ])
            desc.primitives = .triangles([0, 1, 2])
            let mesh = try! MeshResource.generate(from: [desc])
            indicator.name = "PlayIndicator"
            indicator.model = ModelComponent(mesh: mesh, materials: [material])
        }

        // If it's a video—the indicator should be smaller, with background disc
        if video {
            let scaleFactor: Float = 0.4
            indicator.scale = SIMD3(repeating: scaleFactor)

            // Build a circular background using MeshDescriptor
            let segments = 32
            let radius: Float = 0.06
            var circleDesc = MeshDescriptor(name: "circle")
            var positions = [SIMD3<Float>(0,0,0)]
            var indices = [UInt32]()
            for i in 0...segments {
                let angle = Float(i) / Float(segments) * .pi * 2
                positions.append(SIMD3(cos(angle)*radius, sin(angle)*radius, 0))
            }
            for i in 1...segments {
                indices += [0, UInt32(i), UInt32(i+1)]
            }
            circleDesc.positions = MeshBuffers.Positions(positions)
            circleDesc.primitives = .triangles(indices)
            let circleMesh = try! MeshResource.generate(from: [circleDesc])  // :contentReference[oaicite:1]{index=1}

            let bgMat = SimpleMaterial(color: .black, roughness: 1.0, isMetallic: false)
            let bg = ModelEntity(mesh: circleMesh, materials: [bgMat])
            bg.name = "IndicatorBackground"
            bg.position = [0, 0, -0.005]
            indicator.addChild(bg)
        }

        // Position logic
        if video, let model = entity as? ModelEntity, let bounds = model.model?.mesh.bounds {
            let inset: Float = 0.03
            indicator.position = [
                bounds.min.x + inset,
                bounds.min.y + inset,
                bounds.max.z + 0.005
            ]
        } else {
            indicator.position = [0, 0, 0.11]
        }

        entity.addChild(indicator)
    }


    // MARK: - Create-edit-text Gesture
    static func createEditTextGesture(artefactManager: ArtefactManager, appModel: AppModel, openWindow: OpenWindowAction) -> some Gesture {
        return TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                Task { @MainActor in
                    guard !artefactManager.isErasing else { return }
                    guard let artefact = getValidArtefact(from: value.entity, artefactManager: artefactManager) else { return }
                    guard artefact.name == "TextEntity" else {return}
                    artefactManager.textToEditID = artefact.id
                    openWindow(id: appModel.textEditorWindowID)
                }
            }
    }
    
    // MARK: - Helper Method
    @MainActor
    static func getValidArtefact(from entity: Entity, artefactManager: ArtefactManager) -> Entity? {
        // Checks if the targeted entity is directly an artefact, or if its parent is an artefact
        // Returns the matching artefact entity, or nil if neither the entity nor its parent are artefacts
        return artefactManager.artefacts.first { $0 == entity } ?? artefactManager.artefacts.first { $0 == entity.parent }
    }
}

// MARK: - RealityView Extension
extension RealityView {
    func installGestures(artefactManager: ArtefactManager, appModel: AppModel, openWindow: OpenWindowAction) -> some View {
        self.simultaneousGesture(ArtefactGestures.createDragGesture(artefactManager: artefactManager))
            .simultaneousGesture(ArtefactGestures.createRotateGesture(artefactManager: artefactManager))
            .simultaneousGesture(ArtefactGestures.createMagnifyGesture(artefactManager: artefactManager))
            .simultaneousGesture(ArtefactGestures.createRemoveOnTapGesture(artefactManager: artefactManager))
            .simultaneousGesture(ArtefactGestures.createEditTextGesture(artefactManager: artefactManager, appModel: appModel, openWindow: openWindow))
            .simultaneousGesture(ArtefactGestures.createPlayAudioGesture(artefactManager: artefactManager))
            .simultaneousGesture(ArtefactGestures.createPlayVideoGesture(artefactManager: artefactManager))
    }
}
