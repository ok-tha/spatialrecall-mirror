//
//  ImagePickerWindow 2.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 08.05.25.
//



import SwiftUI
import PhotosUI

struct AudioPickerWindow: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    @State private var isPickerPresented = true
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Loading file picker...")
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    artefactManager.selectedAudioURL = url
                    dismiss()
                }
            case .failure(let error):
                print("File selection failed: \(error.localizedDescription)")
            }
        }
        .padding()
        .onChange(of: isPickerPresented) {
            if !isPickerPresented {
                // FileImporter has been dismissed
                print("Importer dismissed without selection (user cancelled).")
                dismiss()
            }
        }
    }
}
