//
//  BoxManager.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 13.04.25.
//


import RealityKit
import SwiftUI

@MainActor
class BoxManager: ObservableObject {
    static let shared = BoxManager()
    @Published var boxes: [Entity] = []
    private var offset: Float = 0.0
    
    func addBox() {
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.3, 0.3, 0.3))
        let material = SimpleMaterial(color: .blue, isMetallic: true)
        let box = ModelEntity(mesh: mesh, materials: [material])
        box.position = SIMD3<Float>(0, 1+offset, -2)
        offset += 0.4
        
        box.components.set(InputTargetComponent(allowedInputTypes: .all))
        box.components.set(GroundingShadowComponent(castsShadow: true))
        box.generateCollisionShapes(recursive: true)
        
        boxes.append(box)
    }
}
