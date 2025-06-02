//
//  AddBoxArtefact.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 02.05.25.
//
//
//import SwiftUI
//import RealityKit
//
//struct AddBoxArtefact: View {
//    @StateObject private var artefactManager = ArtefactManager.shared
//    
//    var body: some View {
//        CreationButton(
//            icon: "cube",
//            label: "Box",
//            action: addBox
//        )
//    }
//    
//    func addBox() {
//        let anchor = AnchorEntity(.head)
//        anchor.anchoring.trackingMode = .once
//        guard var headTransform = artefactManager.getHeadWorldMatrix() else { return }
//        let worldTransform = headTransform * SIMD4<Float>(0,0,-1,0)
//        headTransform.columns.3.x += worldTransform.x
//        headTransform.columns.3.z += worldTransform.z
//        
//        
//        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.3, 0.3, 0.3))
//        let material = SimpleMaterial(color: .blue, isMetallic: true)
//        let box = ModelEntity(mesh: mesh, materials: [material])
//
////        artefactManager.addArtefact(artefact: box ,at: headTransform,)
//    }
//}
