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
               loadInitialArtefacts()
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
    
    func loadInitialArtefacts() {
        loadTextArtefact()
        loadImageArtefact()
        loadObjectArtefact()
        loadVideoArtefact()
        loadAudioArtefact()        
    }

    
    func loadTextArtefact() {
        artefactManager.addText(text: "Test init")
    }
    
    func loadImageArtefact() {
        Task {
            let data = UIImage(named: "garmisch-partenkirchen-header")?.pngData()
            await artefactManager.addImage(data: data!)
        }
    }
    
    func loadObjectArtefact() {
        
    }
    
    func loadVideoArtefact() {
        
    }
    
    func loadAudioArtefact() {
        
    }
}


#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
        .environmentObject(RoomTrackingManager()) // Für Preview
}
