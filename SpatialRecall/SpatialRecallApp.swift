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
        
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    avPlayerViewModel.play()
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    avPlayerViewModel.reset()
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
