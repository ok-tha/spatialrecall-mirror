//
//  ImmersiveView.swift
//  SpatialRecall
//
//  Created by Oliver on 08.04.25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel

    @StateObject private var artefactManager = ArtefactManager.shared
    
    var body: some View {
        ArtefactHudButton()
        RealityView { content in
        }
        update: { content in
            for artefact in artefactManager.artefactEntities{
               if !content.entities.contains(artefact){
                   content.add(artefact)
                   print(artefactManager.artefactEntities.count)
               }
            }
            let entitiesToRemove = content.entities.filter { entity in
                !artefactManager.artefactEntities.contains { $0.id == entity.id }
            }
            entitiesToRemove.forEach { content.remove($0) }
        }
        .installGestures(artefactManager: artefactManager)
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
