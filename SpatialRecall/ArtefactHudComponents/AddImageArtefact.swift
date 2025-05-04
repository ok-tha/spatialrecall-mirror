//
//  AddImmageArtefact.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 04.05.25.
//

import SwiftUI
import RealityKit
import struct PhotosUI.PhotosPickerItem

struct AddImageArtefact: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    @State private var appModel = AppModel()
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var image: Image?
    
    var body: some View {
        Button(action: {openWindow(id: appModel.imagePickerWindowID)}) {
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .padding()
                .foregroundColor(.white)
        }
        .background(Circle().foregroundColor(.gray))
        .frame(width: 56, height: 56) // Total button size
        .onReceive(artefactManager.$selectedImage) { newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    if let cgImage = UIImage(data: data)?.cgImage {
                        let proportionalWidth = Float(cgImage.width) / Float(cgImage.height)
                        
                        let imageHeight: Float = 0.3
                        
                        guard let texture = try? await TextureResource(image: cgImage, options: .init(semantic: .color)) else {return}
                        
                        var frontMaterial = UnlitMaterial()
                        frontMaterial.color = .init(tint: .white, texture: .init(texture))
                        let mesh = MeshResource.generateBox(width: proportionalWidth*imageHeight, height: imageHeight, depth: 0.001, splitFaces: true)
                        let restMaterial = SimpleMaterial(color: .black, isMetallic: false)
                        let image = ModelEntity(mesh: mesh, materials: [frontMaterial,/*fron face*/ restMaterial, restMaterial, restMaterial, restMaterial, restMaterial /*other faces*/])
                        
                        
                        let anchor = AnchorEntity(.head)
                        anchor.anchoring.trackingMode = .once
                        anchor.position = SIMD3<Float>(0,0,-1)
                        
                        artefactManager.addArtefact(artefact: image, anchor: anchor)
                        
                        artefactManager.selectedImage = nil
                    }
                }
            }
        }
    }
    func gcd(_ a: Int, _ b: Int) -> Int {
        var a = a
        var b = b
        while b != 0 {
            let temp = b
            b = a % b
            a = temp
        }
        return a
    }
}
