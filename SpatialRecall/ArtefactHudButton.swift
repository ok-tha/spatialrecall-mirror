//
//  ArtefactHudButton.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 02.05.25.
//

import SwiftUI
import RealityKit

struct ArtefactHudButton: View{
    
    @StateObject private var artefactManager = ArtefactManager.shared
    @State private var inputText: Bool = false
    @State private var text: String = ""
    
    var body: some View{
        RealityView{ content, attachments in
            let headAnchor = AnchorEntity(.head)
            headAnchor.position = [0, -0.2, -0.5]
            
            content.add(headAnchor)
                        
            guard let ui = attachments.entity(for: "HUD") else { return }
            guard let textInput = attachments.entity(for: "TextInputBox") else { return }
            
            ui.components.set(BillboardComponent()) // Face user
            textInput.components.set(BillboardComponent())
            textInput.position = [0, 0.2, 0]
            
            
            
            headAnchor.addChild(ui)
            headAnchor.addChild(textInput)
        }
        attachments: {
            Attachment(id: "TextInputBox") {
                if (inputText){
                    VStack{
                        Text("Input text here...")
                        TextEditor(text: $text)
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(8)
                        
                        HStack{
                            Button( action: {inputText = false}, label: {Text("Cancel")})
                            Button( action: {addText(text: text)}, label: {Text("Save")})
                        }
                    }
                    .frame(width: 200, height: 200)
                    .padding()
                    .background(Color.gray.opacity(0.9))
                    .cornerRadius(45)
                }
            }
            Attachment(id: "HUD") {
                VStack{
                    if(!artefactManager.isErasing) {
                        HStack{
                            AddBoxArtefact()
                            AddImageArtefact()
                            AddTextArtefact(inputText: $inputText, text: $text)
                        }
                    }
                    HStack {
                        Button(action: { artefactManager.isErasing = false }) {
                            Image(systemName: "pencil")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .padding()
                                .foregroundColor(.white)
                        }
                        .background(Circle().foregroundColor(artefactManager.isErasing ? .white.opacity(0) : .gray))
                        .frame(width: 56, height: 56) // Total button size
                        
                        Button(action: { artefactManager.isErasing = true }) {
                            Image(systemName: "eraser")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .padding()
                                .foregroundColor(.white)
                        }
                        .background(Circle().foregroundColor(artefactManager.isErasing ? .gray : .white.opacity(0)))
                        .frame(width: 56, height: 56) // Total button size
                    }
                    .padding(.all, 10)
                    .background(Color.black)
                    .cornerRadius(90)
                }
                .padding()
                .background(Color.gray.opacity(0.7))
                .cornerRadius(45)
            }
        }
    }
    func addText(text: String) {
        inputText=false
        
        let anchor = AnchorEntity(.head)
        anchor.anchoring.trackingMode = .once
        anchor.position = SIMD3<Float>(0,0,-0.5)
        
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.3, 0.3, 0.001))
        let material = SimpleMaterial(color: .yellow, roughness: 0.8 ,isMetallic: true)
        let box = ModelEntity(mesh: mesh, materials: [material])
        box.components.set(TagComponent(tag: "BackgroundBox"))
        
        let textEntity = generateTextEntity(text: text, font: .init(name: "MarkerFelt-Thin", size: 0.01))
        textEntity.name = text
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
