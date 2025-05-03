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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open

                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
