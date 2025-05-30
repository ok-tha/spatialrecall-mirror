//
//  AddAudioArtefact.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 08.05.25.
//

import SwiftUI
import RealityKit
import UniformTypeIdentifiers

struct AddAudioArtefact: View {
    
    @StateObject private var artefactManager = ArtefactManager.shared
    @State private var appModel = AppModel()
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var selectedAudioURL: URL?

    var body: some View {
        CreationButton(
            icon: "waveform",
            label: "Audio",
            action: { openWindow(id: appModel.audioPickerWindowID) }
        )
        .onReceive(artefactManager.$selectedAudioURL) { url in
            guard let url else { return }
            artefactManager.addAudio(url: url)
        }
    }
}
