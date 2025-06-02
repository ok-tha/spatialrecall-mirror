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
                          artefact.name == "AudioEntity",
                          let audioComponent = artefact.components[AudioComponent.self]
                    else { return }

                    let url = audioComponent.url                 // the security-scoped URL
                    let hasScope = url.startAccessingSecurityScopedResource()
                    defer { if hasScope { url.stopAccessingSecurityScopedResource() } }

                    do {
                        // Optionally cache inside the app sandbox
                        let sandboxURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent(url.lastPathComponent)

                        if !FileManager.default.fileExists(atPath: sandboxURL.path) {
                            try FileManager.default.copyItem(at: url, to: sandboxURL)
                        }

                        // Either reuse an existing controller or create one
                        var isPlaying = false
                        if let playBack = audioComponent.playbackController {
                            if playBack.isPlaying {
                                playBack.pause()
                            } else {
                                isPlaying = true
                                playBack.play()
                            }
                            
                        } else {
                            let resource = try AudioFileResource.load(contentsOf: sandboxURL) // RealityKit 1+
                            let controller = artefact.playAudio(resource)
                            artefact.components.set(AudioComponent(url: url, playbackController: controller))
                            isPlaying = true
                        }
                        updatePlayPauseIndicator(for: artefact, isPlaying: isPlaying)

                    } catch {
                        print("Audio load failed: \(error)")
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
                    
                    if let videoComponent = artefact.components[VideoComponent.self] {
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
                        artefact.components[VideoComponent.self] = VideoComponent(player: videoComponent.player, isPlaying: isPlaying)
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
