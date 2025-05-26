//
//  RoomTrackingManager.swift
//  SpatialRecall
//
//  Created by Simon Erhard on 21.05.25.
//
import Foundation
import RealityKit
import ARKit
import Observation

@MainActor
class RoomTrackingManager: ObservableObject {
    static let shared = RoomTrackingManager()
    private let session = ARKitSession()
    private let roomTracking = RoomTrackingProvider()
    
    @Published var currentRoomAnchor: RoomAnchor?
    
    init() {
        Task {
            await startSession()
            await processRoomTrackingUpdates()
        }
    }
    
    func startSession() async {
        do {
            try await session.run([roomTracking])
            print("Room Tracking Session gestartet")
        } catch {
            print("Fehler beim Starten der Session: \(error)")
        }
    }
    
    func processRoomTrackingUpdates() async {
        for await update in roomTracking.anchorUpdates {
            switch update.event {
            case .added, .updated:
                print("RoomAnchor hinzugefügt/aktualisiert: \(update.anchor.id)")
                currentRoomAnchor = update.anchor
                // Hier kannst du weitere Aktionen machen,
                // z.B. Entities zur Scene hinzufügen oder UI updaten
                
            case .removed:
                print("RoomAnchor entfernt: \(update.anchor.id)")
                if currentRoomAnchor?.id == update.anchor.id {
                    currentRoomAnchor = nil
                }
            }
        }
    }
}
