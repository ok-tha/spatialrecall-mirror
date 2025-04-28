//
//  ContentView.swift
//  SpatialRecall
//
//  Created by Oliver on 08.04.25.
//

import SwiftUI
import RealityKit


struct ContentView: View {
    
    @StateObject var boxManager = BoxManager.shared
    
    var body: some View {
        VStack {
            ToggleImmersiveSpaceButton()
            Button {
                //boxManager.addBox()
            } label: {
                Text("Click me")
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
