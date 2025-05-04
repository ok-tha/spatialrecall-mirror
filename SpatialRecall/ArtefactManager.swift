//
//  ArtefactManager.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 02.05.25.
//

import RealityKit
import SwiftUI

@MainActor
class ArtefactManager: ObservableObject {
    static let shared = ArtefactManager()
    @Published var artefacts: [Entity] = []
    @Published var artefactEntities: [Entity] = []
    
    @Published var isErasing = false //to check if should delete on click
    
    func addArtefact(artefact: Entity, anchor: AnchorEntity) {
        
        artefact.components.set(InputTargetComponent(allowedInputTypes: .all))
        artefact.components.set(GroundingShadowComponent(castsShadow: true))
        artefact.generateCollisionShapes(recursive: true)
        artefact.position = .zero
        
        anchor.children.append(artefact)
        
        artefactEntities.append(anchor)
        artefacts.append(artefact)
    }
}
