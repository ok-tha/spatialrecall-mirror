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
                    if artefactManager.artefacts.contains(entity) {
                        var artefact: Entity = artefactManager.artefacts.first(where: { $0 == entity })!
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
                    if artefactManager.artefacts.contains(entity) {
                        var artefact: Entity = artefactManager.artefacts.first(where: { $0 == entity })!
                        artefactManager.artefacts.removeAll(where: { $0 == entity})
                        if artefact.parent is AnchorEntity {
                            artefact = artefact.parent!
                        }
                        artefactManager.artefactEntities.removeAll { $0 == artefact }
                        
                    }
                }
            }
    }
    
}

extension RealityView {
    func installGestures(artefactManager: ArtefactManager) -> some View {
        simultaneousGesture(ArtefactGestures.createDragGesture(artefactManager: artefactManager))
            .simultaneousGesture(ArtefactGestures.createRemoveOnTapGesture(artefactManager: artefactManager))
    }
}
