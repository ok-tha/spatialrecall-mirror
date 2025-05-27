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
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Add Text")
                .font(.headline)
            
            TextEditor(text: $textInput)
                .frame(minHeight: 80, maxHeight: 160)
                .padding(12)
                .background(.white.opacity(0.9))
                .foregroundColor(.black)
                .cornerRadius(12)
                .focused($isTextEditorFocused)
                .onSubmit {
                    onSubmit()
                }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    withAnimation {
                        isTextInput = false
                        textInput = ""
                    }
                }                
                Button("Add") {
                    onSubmit()
                }
                .disabled(textInput.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            isTextEditorFocused = true
        }
    }
    
    func onSubmit() {
        if !textInput.isEmpty {
            addText(textInput: textInput)
            withAnimation {
                isTextInput = false
                textInput = ""
            }
        }
    }
    
    func addText(textInput: String) {
        let trimmedText = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
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
    }
}
