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
        Button(action: { openWindow(id: appModel.audioPickerWindowID) }) {
            Image(systemName: "waveform")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .padding()
                .foregroundColor(.white)
        }
        .background(Circle().foregroundColor(.gray))
        .frame(width: 56, height: 56)
        .onReceive(artefactManager.$selectedAudioURL) { url in
            Task {
                guard let url else { return }
                print("Adding Audio", url.lastPathComponent)
                let anchor = AnchorEntity(.head)
                anchor.anchoring.trackingMode = .once
                anchor.position = SIMD3<Float>(0, 0, -1)

                let mesh = MeshResource.generateSphere(radius: 0.1)
                let material = SimpleMaterial(color: .red, isMetallic: true)
                let sphere = ModelEntity(mesh: mesh, materials: [material])
                
                sphere.name = "AudioEntity"
                sphere.components.set(AudioComponent(url: url))
                sphere.components.set(BillboardComponent())
                
                ArtefactGestures.updatePlayPauseIndicator(for: sphere, isPlaying: false)
                
                artefactManager.selectedAudioURL = nil
                
                
                artefactManager.addArtefact(artefact: sphere, anchor: anchor)
                
                dismissWindow(id: appModel.audioPickerWindowID)
            }
        }
    }
}
