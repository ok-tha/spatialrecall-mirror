//
//  AppModel.swift
//  SpatialRecall
//
//  Created by Oliver on 08.04.25.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    let imagePickerWindowID = "ImagePickerWindow"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
}
