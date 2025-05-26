//
//  TextInputBox.swift
//  SpatialRecall
//
//  Created by Kühle, Oliver on 26.05.25.
//

import SwiftUI
import RealityKit

struct TextInputBox: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    @Binding var isTextInput: Bool
    @Binding var textInput: String
    
    var body: some View {
        if isTextInput {            
            VStack {
                Text("Input textInput here...")
                TextEditor(text: $textInput)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(8)
                
                HStack{
                    Button( action: {isTextInput = false}, label: {Text("Cancel")})
                    Button( action: {addText(textInput: textInput)}, label: {Text("Save")})
                }
            }
            .frame(width: 200, height: 200)
            .padding()
            .background(Color.gray.opacity(0.9))
            .cornerRadius(45)
        }
    }
    
    func addText(textInput: String) {
        let trimmedText = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        isTextInput = false
        
        let anchor = AnchorEntity(.head)
        anchor.anchoring.trackingMode = .once
        anchor.position = SIMD3<Float>(0,0,-0.5)
        
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.3, 0.3, 0.001))
        let material = SimpleMaterial(color: .yellow, roughness: 0.8 ,isMetallic: true)
        let box = ModelEntity(mesh: mesh, materials: [material])
        box.components.set(TagComponent(tag: "BackgroundBox"))
        
        let textEntity = generateTextEntity(text: trimmedText, font: .init(name: "MarkerFelt-Thin", size: 0.01))
        textEntity.name = trimmedText
        textEntity.components.set(TagComponent(tag: "TextField"))
        
        let containerEntity = Entity()
        containerEntity.addChild(box)
        containerEntity.addChild(textEntity)
        
        centerTextAndBackground(textEntity: textEntity)
        
        containerEntity.name = "TextEntity"
        
        resizeBox(box: box, textEntity: textEntity)
        artefactManager.addArtefact(artefact: containerEntity ,anchor: anchor)
        
        // Clear textInput after successful addition
        self.textInput = ""
    }
}
