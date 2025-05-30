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
                await artefactManager.addObject(url: url)
            }
        }
    }
}
