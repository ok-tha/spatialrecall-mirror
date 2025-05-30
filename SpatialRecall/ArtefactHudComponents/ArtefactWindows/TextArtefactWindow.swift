//
//  TextArtefactWindow.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 06.05.25.
//

import SwiftUI
import RealityKit


struct TextArtefactWindow: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var artefactManager = ArtefactManager.shared
    
    @State private var text = ""
    
    var body: some View {
        VStack(spacing: 12) {
            Text(artefactManager.textToEditID != nil ? "Edit Text" : "Add Text")
                .font(.headline)
            TextEditor(text: $text)
                .frame(minHeight: 80)
                .padding(12)
                .background(.white.opacity(0.9))
                .foregroundColor(.black)
                .cornerRadius(12)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                Button("Speichern") {
                    saveChanges()
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            text = getCurrentText()
        }
    }

    
    
    func getCurrentText() -> String {
        guard let artefact = artefactManager.artefacts.first(where: {$0.id == artefactManager.textToEditID}) else {
            artefactManager.textToEditID = nil
            return ""
        }
        for child in artefact.children {
            if let tagComp = child.components[TagComponent.self],
               tagComp.tag == "TextField" {
                return child.name
            }
        }
        return ""
    }
    
    func saveChanges() {
        guard let artefact = artefactManager.artefacts.first(where: {$0.id == artefactManager.textToEditID}) else {
            artefactManager.textToEditID = nil
            artefactManager.addText(text: text)
            dismiss()
            return
        }
        let newText = generateTextEntity(text: text)
        newText.components.set(TagComponent(tag: "TextField"))
        
        var textEntity: ModelEntity?
        var backgroundEntity: ModelEntity?
        
        artefact.children.removeAll(where: {
            guard let tagComp = $0.components[TagComponent.self] else { return false }
            if tagComp.tag == "TextField" {return true}
            return false
        })
        
        centerTextAndBackground(textEntity: newText)
        
        artefact.children.append(newText)
        
        for child in artefact.children {
            guard let tagComp = child.components[TagComponent.self] else { dismiss(); return }
            if tagComp.tag == "TextField" {
                guard let modelEnt = child as? ModelEntity else { dismiss(); return }
                textEntity = modelEnt
            }
            if tagComp.tag == "BackgroundBox"{
                guard let modelEnt = child as? ModelEntity else { dismiss(); return }
                backgroundEntity = modelEnt
            }
        }
        guard backgroundEntity != nil && textEntity != nil else { dismiss(); return }
        resizeBox(box: backgroundEntity!, textEntity: textEntity!)
        artefactManager.textToEditID = nil
        dismiss()
    }
    
}

// MARK: - Preview

#Preview {
    TextArtefactWindow()
}
