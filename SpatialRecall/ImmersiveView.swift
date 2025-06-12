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
    @StateObject private var artefactManager = ArtefactManager.shared
    @StateObject private var worldTrackingManager = WorldTrackingManager.shared

    var body: some View {
        ArtefactHudButton()
        ZStack {
            RealityView { content in
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

        }
    }
}


#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
