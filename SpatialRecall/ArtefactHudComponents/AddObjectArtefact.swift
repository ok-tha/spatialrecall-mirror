//
//  AddBoxArtefact.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 02.05.25.
//

import SwiftUI
import RealityKit

struct AddObjectArtefact: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    @State private var appModel = AppModel()
    
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(action: {
            openWindow(id: appModel.objectPickerWindowID)
        }) {
            Image(systemName: "cube")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .padding()
                .foregroundColor(.white)
        }
        .background(Circle().foregroundColor(.gray))
        .frame(width: 56, height: 56)
        .onReceive(artefactManager.$selectedObjectURL) { url in
            Task {
                guard let url else { return }

                do {
                    let modelEntity = try await ModelEntity(contentsOf: url)
                    let anchor = AnchorEntity(.head)
                    anchor.anchoring.trackingMode = .once
                    anchor.position = SIMD3<Float>(0, 0, -1)
                    anchor.addChild(modelEntity)
                    artefactManager.addArtefact(artefact: modelEntity, anchor: anchor)
                    artefactManager.selectedObjectURL = nil
                    
                } catch {
                    print("Failed to create ModelEntity: \(error)")
                }
            }
        }
    }
}
