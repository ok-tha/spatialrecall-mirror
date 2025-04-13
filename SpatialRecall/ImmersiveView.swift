//
//  ImmersiveView.swift
//  SpatialRecall
//
//  Created by Oliver on 08.04.25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel

    @StateObject var boxManager = BoxManager.shared
    
    var body: some View {
        RealityView { content in
            
        } update: {content in
            for box in boxManager.boxes{
                if !content.entities.contains(box){
                    content.add(box)
                }
            }
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
