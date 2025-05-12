//
//  AddTextArtefact.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 06.05.25.
//


import SwiftUI
import RealityKit
import RealityKitContent

struct AddTextArtefact: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    
    
    @Binding var inputText: Bool
    @Binding var text: String
    
    var body: some View {
        VStack{
            Button(action: {inputText = true;}) {
                Image(systemName: "keyboard")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .padding()
                    .foregroundColor(.white)
            }
            .background(Circle().foregroundColor(.gray))
            .frame(width: 56, height: 56) // Total button size
        }.onDisappear(){
            inputText = false
        }
    }    
}

public func generateTextEntity(text: String, font: UIFont? = .boldSystemFont(ofSize: 0.01), color: UIColor? = .black) -> ModelEntity {
    let textMesh = MeshResource.generateText(text, extrusionDepth: 0.0001, font: font!, containerFrame: CGRect(x:0,y:0, width: 0.5, height: 0.5), alignment: .center, lineBreakMode: .byWordWrapping)
    let textMaterial = SimpleMaterial(color: color!, isMetallic: false)
    return ModelEntity(mesh: textMesh, materials: [textMaterial])
}

public func resizeBox(box: ModelEntity,textEntity: ModelEntity){
    
    if let textBounds = textEntity.model?.mesh.bounds {
        let textSize = textBounds.extents
        
        let padding: SIMD3<Float> = SIMD3<Float>(0.02, 0.02, 0.0)
        let newSize = textSize + padding
        
        let scaleX = newSize.x / box.model!.mesh.bounds.extents.x
        let scaleY = newSize.y / box.model!.mesh.bounds.extents.y
        
        box.scale = SIMD3<Float>(scaleX, scaleY, 1.0)
    }
}

public func centerTextAndBackground(textEntity: ModelEntity) {
    if let textBounds = textEntity.model?.mesh.bounds {
        textEntity.position = SIMD3<Float>(
            -textBounds.center.x,
             -textBounds.center.y,
             0.001
        )
    }
}

struct TagComponent: Component {
    var tag: String
}
