//
//  SpatialRecallApp.swift
//  SpatialRecall
//
//  Created by Oliver on 08.04.25.
//
import SwiftUI

@main
struct SpatialRecallApp: App {
    
    @State private var appModel = AppModel()
    @State private var avPlayerViewModel = AVPlayerViewModel()
    @StateObject private var roomTrackingManager = RoomTrackingManager() // ← HIER NEU

    var body: some Scene {
        WindowGroup(id: appModel.imagePickerWindowID) {
            ImagePickerWindow()
                .environment(appModel)
            ReactivateImmersiveSpaceButton()
                .environment(appModel)
        }
        WindowGroup(id: appModel.textEditorWindowID){
            TextArtefactWindow()
            ReactivateImmersiveSpaceButton()
                .environment(appModel)
        }
        WindowGroup(id: appModel.audioPickerWindowID) {
            AudioPickerWindow()
                .environment(appModel)
            ReactivateImmersiveSpaceButton()
                .environment(appModel)
        }.defaultSize(width: 400, height: 200)
        WindowGroup(id: appModel.objectPickerWindowID) {
            ObjectPickerWindow()
                .environment(appModel)
            ReactivateImmersiveSpaceButton()
                .environment(appModel)
        }.defaultSize(width: 400, height: 200)
        WindowGroup(id: appModel.videoPickerWindowID) {
            VideoPickerWindow()
                .environment(appModel)
            ReactivateImmersiveSpaceButton()
                .environment(appModel)
        }.defaultSize(width: 400, height: 300)
        
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .environmentObject(roomTrackingManager) // ← HIER NEU
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    avPlayerViewModel.play()
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    avPlayerViewModel.reset()
                }
        }
        .immersionStyle(selection: .constant(.full), in: .mixed)
        .immersionStyle(selection: .constant(.mixed), in: .full)
    }
}
