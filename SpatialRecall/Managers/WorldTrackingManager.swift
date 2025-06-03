//
//  WorldTrackingManager.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 30.05.25.
//

import ARKit
import RealityKit
import Observation
import SwiftUI

@MainActor
class WorldTrackingManager: ObservableObject {
    static let shared = WorldTrackingManager()
    
    private lazy var artefactManager = ArtefactManager.shared
    
    let session = ARKitSession()
    let worldInfo = WorldTrackingProvider()
    
    
    var isWorldTrackingSupported: Bool = true
    
    var isSessionRunning = false

    
    init(){
        Task{
            await startSession()
            Task{
                await processWorldTrackingUpdates()
            }
        }
    }
    
    private var sessionReadyContinuations: [CheckedContinuation<Void, Never>] = []
        
    func waitForSessionReady() async {
        if isSessionRunning {
            return
        }
        
        await withCheckedContinuation { continuation in
            sessionReadyContinuations.append(continuation)
        }
    }
    
    func startSession() async {
        guard WorldTrackingProvider.isSupported else {
            print("World Tracking wird auf diesem Gerät nicht unterstützt (bspw. Simulator)")
            isWorldTrackingSupported = false
            return
        }
        
        do {
            try await session.run([worldInfo])
            print("World Tracking Session gestartet")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { [self] in
                isSessionRunning = true
                // Resume all waiting continuations
                for continuation in sessionReadyContinuations {
                    continuation.resume()
                }
                sessionReadyContinuations.removeAll()
            })
        } catch {
            print("Fehler beim Starten der Session: \(error)")
        }
    }
    func processWorldTrackingUpdates() async {
        for await update in worldInfo.anchorUpdates {
            switch update.event {
            case .added:
                print("Anchor added")
            case .updated:
                print("Anchor updated")
//                guard let artefact = artefactManager.artefacts.first(where: { artefact in
//                    guard let persistentIDComponent = artefact.components[PersistentIDComponent.self] else { return false }
//                    guard let persistentEntity = artefactManager.persistentArtefacts.first(where: {$0.id == persistentIDComponent.persistentID}) else { return false }
//                    return update.anchor.id == persistentEntity.worldAnchor
//                }) else { return }
//                
//                var anchor = AnchorEntity(world: .zero)
//                anchor = AnchorEntity(world: update.anchor.originFromAnchorTransform)
//                
//                anchor.children.append(artefact)
//                artefactManager.artefactEntities.removeAll { $0.id == artefact.parent?.id }
//                artefactManager.artefactEntities.append(anchor)
            case .removed:
                print("Anchor removed")
                break
            }
        }
    }
    
    func getHeadWorldPositionAsMatrix() -> simd_float4x4? {
        let deviceAnchor = worldInfo.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
        guard let deviceAnchor, deviceAnchor.isTracked else { return nil}
        print(deviceAnchor.originFromAnchorTransform)
        var matrix = deviceAnchor.originFromAnchorTransform
        matrix.columns.0 = simd_float4(1.0,0,0,0)
        matrix.columns.1 = simd_float4(0,1.0,0,0)
        matrix.columns.2 = simd_float4(0,0,1.0,0)
        print(matrix)
        return matrix
    }
    
    func removeUnusedAnchors() async {
        guard let allAnchors = await worldInfo.allAnchors else { return }
        for anchor in allAnchors {
            if !artefactManager.persistentArtefacts.contains(where: {anchor.id == $0.worldAnchor}){
                try? await worldInfo.removeAnchor(anchor)
            }
        }
    }
}
