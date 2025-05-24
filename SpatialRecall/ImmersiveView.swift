//
//  ImmersiveView.swift
//  SpatialRecall
//
//  Created by Oliver on 08.04.25.
//
import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.openWindow) var openWindow
    @EnvironmentObject var roomTrackingManager: RoomTrackingManager

    @StateObject private var artefactManager = ArtefactManager.shared

    var body: some View {
        ArtefactHudButton()
        ZStack {
            RealityView { content in
                // Add initial RealityKit content here if needed
                let anchor = AnchorEntity(world: SIMD3<Float>(0, 1.5, -1)) // 1.5 m hoch, 1 m vor dem User
                    let mesh = MeshResource.generateText("Hallo Welt", extrusionDepth: 0.01, font: .systemFont(ofSize: 0.2))
                    let material = SimpleMaterial(color: .blue, isMetallic: false)
                    let model = ModelEntity(mesh: mesh, materials: [material])
                    anchor.addChild(model)
                    content.add(anchor)
            } update: { content in
                // Synchronisiere Artefakte mit RealityKit-Szene
                for artefact in artefactManager.artefactEntities {
                    if !content.entities.contains(where: { $0.id == artefact.id }) {
                        content.add(artefact)
                    }
                }
                let entitiesToRemove = content.entities.filter { entity in
                    !artefactManager.artefactEntities.contains(where: { $0.id == entity.id })
                }
                entitiesToRemove.forEach { content.remove($0) }
            }
            .installGestures(
                artefactManager: artefactManager,
                appModel: appModel,
                openWindow: openWindow
            )

            // Optional: Anzeige des RoomAnchor-Status
            if let anchor = roomTrackingManager.currentRoomAnchor {
                VStack {
                    Spacer()
                    Text("Raumanker aktiv: \(anchor.id.uuidString)")
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
        .task {
            // Session starten, falls nicht bereits durch init gestartet
            await roomTrackingManager.startSession()
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
        .environmentObject(RoomTrackingManager()) // Für Preview
}
