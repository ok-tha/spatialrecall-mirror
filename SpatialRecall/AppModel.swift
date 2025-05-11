//
//  AppModel.swift
//  SpatialRecall
//
//  Created by Oliver on 08.04.25.
//

import SwiftUI
import RealityKit

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    let imagePickerWindowID = "ImagePickerWindow"
    let textEditorWindowID = "TextEditorWindow"
    let audioPickerWindowID = "AudioPickerWindow"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
}



public struct AudioComponent: Component {
    var url: URL
    var playbackController: AudioPlaybackController?
}
