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
    @State private var isPickerPresented = false
    
    var body: some View {
        Button(action: { isPickerPresented = true }) {
            Text("Select Audio File")
        }
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    artefactManager.selectedAudioURL = url
                }
            case .failure(let error):
                print("File selection failed: \(error.localizedDescription)")
            }
        }
        .padding()
    }
}
