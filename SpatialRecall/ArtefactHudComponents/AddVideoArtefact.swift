//
//  AddVideoArtefact.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 12.05.25.
//


import SwiftUI
import RealityKit
import AVKit
import UniformTypeIdentifiers

struct AddVideoArtefact: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    @State private var appModel = AppModel()
    
    @Environment(\.openWindow) private var openWindow
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        CreationButton(
            icon: "play.rectangle",
            label: "Video",
            action: { openWindow(id: appModel.videoPickerWindowID) }
        )
        .onReceive(artefactManager.$selectedVideoURL) { url in
            Task{
                guard let url else { return }
                await artefactManager.addVideo(url: url)
            }
        }
    }
}

struct VideoComponent: Component {
    var player: AVPlayer
    var isPlaying: Bool
}

func getVideoSize(url: URL) async -> CGSize?{
    guard let track = (try? await AVURLAsset(url: url).loadTracks(withMediaType: AVMediaType.video))?.first,
          let (naturalSize, preferredTransform) = try? await track.load(.naturalSize, .preferredTransform) else { return nil }
    let size = naturalSize.applying(preferredTransform)
    return CGSize(width: size.width, height: size.height)
}
