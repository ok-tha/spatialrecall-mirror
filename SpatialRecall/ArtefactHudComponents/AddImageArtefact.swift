//
//  AddImmageArtefact.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 04.05.25.
//

import SwiftUI
import RealityKit

struct AddImmageArtefact: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    @State private var appModel = AppModel()
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button(action: {openWindow(id: appModel.imagePickerWindowID)}) {
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
    
}
