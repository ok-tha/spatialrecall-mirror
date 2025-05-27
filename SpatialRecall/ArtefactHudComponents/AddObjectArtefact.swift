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
        CreationButton(
            icon: "cube.transparent",
            label: "Object",
            action: { openWindow(id: appModel.objectPickerWindowID) }
        )
        .onReceive(artefactManager.$selectedObjectURL) { url in
            Task {
                guard let url else { return }
                
                // Request access to security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    print("Failed to access security-scoped resource")
                    return
                }
                
                defer {
                    // Always stop accessing when done
                    url.stopAccessingSecurityScopedResource()
                }
                
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
