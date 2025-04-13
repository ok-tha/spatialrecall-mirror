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

    @StateObject var boxManager = BoxManager.shared
    
    var body: some View {
        RealityView { content in
            
        } update: {content in
            for box in boxManager.boxes{
                if !content.entities.contains(box){
                    content.add(box)
                }
            }
        }.gesture(drag)
    }
    
    var drag: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                let entity = value.entity
                if(boxManager.boxes.contains(entity)) {
                    let box: Entity = boxManager.boxes.first(where: {entity == $0})!
                    box.position = value.convert(value.location3D, from: .local, to: box.parent!)
                }
            }
            .onEnded { value in
                print("DragGesture ended: \(value)")
            }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
