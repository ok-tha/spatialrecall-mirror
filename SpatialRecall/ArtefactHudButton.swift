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
    
    var body: some View{
        RealityView{ content, attachments in
            let headAnchor = AnchorEntity(.head)
            headAnchor.position = [0, -0.2, -0.5]
            
            content.add(headAnchor)
                        
            guard let ui = attachments.entity(for: "HUD") else { return }
            
            ui.components.set(BillboardComponent()) // Face user
            headAnchor.addChild(ui)
        }
        attachments: {
            Attachment(id: "HUD") {
                VStack{
                    if(!artefactManager.isErasing) {
                        HStack{
                            AddBoxArtefact()
                            AddImageArtefact()
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
}
