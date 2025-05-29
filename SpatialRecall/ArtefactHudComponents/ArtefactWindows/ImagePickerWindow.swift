//
//  ImagePickerWindow.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 04.05.25.
//

import SwiftUI
import PhotosUI

struct ImagePickerWindow: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    
    var body: some View {
        PhotosPicker(
            selection: $artefactManager.selectedImage,
            matching: .images,
        ) {
            Label("Select Image", systemImage: "photo")
        }
        .photosPickerStyle(.compact)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    ImagePickerWindow()
}
