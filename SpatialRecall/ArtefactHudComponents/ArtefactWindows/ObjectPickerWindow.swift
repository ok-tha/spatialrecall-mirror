//
//  ObjectPickerWindow.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 12.05.25.
//

import SwiftUI
import UniformTypeIdentifiers



struct ObjectPickerWindow: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    @State private var isPickerPresented = true
    @State private var appModel = AppModel()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Loading file picker...")
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: [.obj, .stl, .ply, .usdz],
            allowsMultipleSelection: false,
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    artefactManager.selectedObjectURL = url
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

extension UTType {
    static let obj = UTType(filenameExtension: "obj")!
    static let stl = UTType(filenameExtension: "stl")!
    static let ply = UTType(filenameExtension: "ply")!
    
}

// MARK: - Preview

#Preview {
    ObjectPickerWindow()
}
