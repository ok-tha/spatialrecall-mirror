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
}
