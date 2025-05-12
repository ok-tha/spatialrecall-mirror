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
        VStack{
            TextField(getCurrentText(), text: $text)
            Button( action: {saveChanges()}, label: {Text("Save")})
        }
    }
    
    
    func getCurrentText() -> String {
        guard let artefact = artefactManager.artefacts.first(where: {$0.id == artefactManager.textToEditID}) else {
            artefactManager.textToEditID = nil
            dismiss()
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
        dismiss()
    }
}
