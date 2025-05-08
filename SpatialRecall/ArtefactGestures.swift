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
                    print(checkIfIsArtefact(entity: entity, artefactManager: artefactManager))
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
    }
}
