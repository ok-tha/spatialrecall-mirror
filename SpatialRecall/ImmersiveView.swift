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
    @State private var buttonEntity: ModelEntity? = nil

    
    var body: some View {
        RealityView { content in
            
            let buttonEntity = ModelEntity(mesh: .generateBox(size:0.05))
            buttonEntity.name = "Button"

            buttonEntity.generateCollisionShapes(recursive: false)
            buttonEntity.components.set(InputTargetComponent(allowedInputTypes: .all))
            
            let anchor = AnchorEntity(.head)
            anchor.position = SIMD3<Float>(0.25,-0.25,-0.5)
            
            
            anchor.children.append(buttonEntity)
            self.buttonEntity = buttonEntity
            content.add(anchor)
            
        }
        update: {content in
            for box in boxManager.boxEntities{
                if !content.entities.contains(box){
                    content.add(box)
                }
            }
        }
            .gesture(drag)
            .gesture(click)
    }
    
    var drag: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                let entity = value.entity
                if(boxManager.boxes.contains(entity)) {
                    var box: Entity = boxManager.boxes.first(where: {entity == $0})!
                    if (box.parent is AnchorEntity){
                        box = box.parent!
                    }
                    //print(value.convert(value.location3D, from: .local, to: box.parent!))
                    let translation = SIMD3<Float>(value.translation3D / 100.0)
                    let newPosition = entity.position + SIMD3<Float>(translation.x, translation.y, translation.z)

                    print(newPosition)
                    box.position = newPosition
                }
            }
    }
    
    var click: some Gesture {
        TapGesture()
            .targetedToAnyEntity()
            .onEnded{ val in
                if(val.entity.name == "Button") {
                    let anchor = AnchorEntity(.head)
                    anchor.anchoring.trackingMode = .once
                    anchor.position = SIMD3<Float>(0,0,-1)
                    boxManager.addBox(anchor: anchor)
                    print("Got tap on \(val.entity)")
                }
            }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
