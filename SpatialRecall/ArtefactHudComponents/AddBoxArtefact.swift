//
//  AddBoxArtefact.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 02.05.25.
//

import SwiftUI
import RealityKit

struct AddBoxArtefact: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    
    var body: some View {
        Button(action: {addBox()}) {
            Image(systemName: "cube")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .padding()
                .foregroundColor(.white)
        }
        .background(Circle().foregroundColor(.gray))
        .frame(width: 56, height: 56) // Total button size
    }
    
    func addBox() {
        let anchor = AnchorEntity(.head)
        anchor.anchoring.trackingMode = .once
        anchor.position = SIMD3<Float>(0,0,-1)
        
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.3, 0.3, 0.3))
        let material = SimpleMaterial(color: .blue, isMetallic: true)
        let box = ModelEntity(mesh: mesh, materials: [material])

        artefactManager.addArtefact(artefact: box ,anchor: anchor)
    }
}
