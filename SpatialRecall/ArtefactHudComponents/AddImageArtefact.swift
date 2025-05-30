//
//  AddImmageArtefact.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 04.05.25.
//

import SwiftUI
import RealityKit
import struct PhotosUI.PhotosPickerItem

struct AddImageArtefact: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    @State private var appModel = AppModel()
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var image: Image?
    
    var body: some View {
        CreationButton(
            icon: "photo",
            label: "Image",
            action: { openWindow(id: appModel.imagePickerWindowID) }
        )
        .onReceive(artefactManager.$selectedImage) { newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await artefactManager.addImage(data: data)
                }
            }
        }
    }
}
