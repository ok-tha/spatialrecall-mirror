//
//  VideoPickerWindow.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 12.05.25.
//

import SwiftUI
import PhotosUI
import AVKit

struct VideoPickerWindow: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    @State private var isFilePickerPresented = false
    @State private var isPhotoPickerPresented = false
    @State private var appModel = AppModel()
    
    @State private var selectedVideoPickerItem: PhotosPickerItem?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack{
            Button(action: {isFilePickerPresented = true}){
                Text("Select video from file system")
            }
            PhotosPicker(
                selection: $selectedVideoPickerItem,
                matching: .videos,
            ) {
                Label("Select Video", systemImage: "movieclapper")
            }
            .photosPickerStyle(.presentation)
            .padding()
            .onChange(of: selectedVideoPickerItem) {
                Task{
                    guard let movie = try await selectedVideoPickerItem?.loadTransferable(type: Movie.self) else { return }
                    artefactManager.selectedVideoURL = movie.url
                    dismiss()
                }
            }
            
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.video],
            allowsMultipleSelection: false,
        ) { result in
            print(result)
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    artefactManager.selectedVideoURL = url
                    dismiss()
                }
            case .failure(let error):
                print("File selection failed: \(error.localizedDescription)")
            }
        }
        .padding()
            
        
    }
}


struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "movie.mp4")

            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }

            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}

// MARK: - Preview

#Preview {
    VideoPickerWindow()
}
