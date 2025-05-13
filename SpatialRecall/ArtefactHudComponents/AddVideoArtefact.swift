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
        VStack {
            Button(action: {
                openWindow(id: appModel.videoPickerWindowID)
            }) {
                Image(systemName: "movieclapper")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .padding()
                    .foregroundColor(.white)
            }
                .background(Circle().foregroundColor(.gray))
                .frame(width: 56, height: 56)        }
        .onReceive(artefactManager.$selectedVideoURL) { url in
            Task{
                guard let url else { return }
                guard let videoSize = await getVideoSize(url: url) else { return }
                let proportionalWidth:Float = Float(videoSize.width / videoSize.height)
                let videoHeight: Float = 0.3
                print(proportionalWidth)
                let avPlayer = AVPlayer(url: url)
                
                let videoMaterial = VideoMaterial(avPlayer: avPlayer)
                
                let mesh = MeshResource.generateBox(width: proportionalWidth*videoHeight, height: videoHeight, depth: 0.001, splitFaces: true)
                let restMaterial = SimpleMaterial(color: .black, isMetallic: false)
                let video = ModelEntity(mesh: mesh, materials: [videoMaterial,/*fron face*/ restMaterial, restMaterial, restMaterial, restMaterial, restMaterial /*other faces*/])
                video.name = "VideoEntity"
                video.components.set(VideoComponent(player: avPlayer, isPlaying: false))
                
                let anchor = AnchorEntity(.head)
                anchor.anchoring.trackingMode = .once
                anchor.position = SIMD3<Float>(0, 0, -1)
                anchor.addChild(video)
                
                artefactManager.addArtefact(artefact: video, anchor: anchor)
                
                artefactManager.selectedVideoURL = nil
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
