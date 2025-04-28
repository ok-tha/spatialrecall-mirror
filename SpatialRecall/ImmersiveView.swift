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
            
            let textMesh = MeshResource.generateText(
                "Test",
                extrusionDepth: 0.001,
                font: .boldSystemFont(ofSize: 0.05),
                containerFrame: .zero,
                alignment: .center
            )

            let textMaterial = SimpleMaterial(color: .cyan, isMetallic: false)
            let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])

            let textBounds = textEntity.model?.mesh.bounds.extents ?? SIMD3<Float>(0.1, 0.05, 0.01)

            let padding: Float = 0.02
            let backgroundWidth = textBounds.x + padding
            let backgroundHeight = textBounds.y + padding
            let backgroundDepth: Float = 0.001 // very thin

            let backgroundMesh = MeshResource.generateBox(
                size: [backgroundWidth, backgroundHeight, backgroundHeight],
                cornerRadius: backgroundHeight / 2 // Rounded ends -> pill shape
            )

            let backgroundMaterial = SimpleMaterial(
                color: .white.withAlphaComponent(0.5), // semi-transparent white
                isMetallic: false
            )

            let backgroundEntity = ModelEntity(mesh: backgroundMesh, materials: [backgroundMaterial])

            // --- VERY IMPORTANT ---
            // Center the background under the text
            // By default, meshes' pivot is centered at (0,0,0),
            // but the text may not be centered correctly (due to how text mesh is generated)
            // Fixing textEntity pivot to center:

            if let textBounds = textEntity.model?.mesh.bounds {
                textEntity.position = SIMD3<Float>(
                    -textBounds.center.x,
                    -textBounds.center.y,
                    0.0
                )
            }

            // Move background slightly back so they don't overlap visually
            backgroundEntity.position.z = -0.001

            backgroundEntity.name = "Button"
            backgroundEntity.generateCollisionShapes(recursive: false)
            backgroundEntity.components.set(InputTargetComponent(allowedInputTypes: .all))

            // --- Group into a parent entity ---
            let containerEntity = Entity()
            containerEntity.addChild(backgroundEntity)
            containerEntity.addChild(textEntity)
            
            containerEntity.components.set(BillboardComponent())

            let anchor = AnchorEntity(.head)
            anchor.position = SIMD3<Float>(0, -0.25, -0.5)
            


            // Add the container to the anchor
            anchor.addChild(containerEntity)
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


