//
//  ToggleImmersiveSpaceButton.swift
//  SpatialRecall
//
//  Created by Oliver on 08.04.25.
//

import SwiftUI

struct ReactivateImmersiveSpaceButton: View {

    @Environment(AppModel.self) private var appModel

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        if(appModel.immersiveSpaceState != .open){
            Button {
                Task { @MainActor in
                    switch appModel.immersiveSpaceState {
                    case .closed:
                        appModel.immersiveSpaceState = .inTransition
                        switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                        case .opened:
                            // Don't set immersiveSpaceState to .open because there
                            // may be multiple paths to ImmersiveView.onAppear().
                            // Only set .open in ImmersiveView.onAppear().
                            break
                            
                        case .userCancelled, .error:
                            // On error, we need to mark the immersive space
                            // as closed because it failed to open.
                            fallthrough
                        @unknown default:
                            // On unknown response, assume space did not open.
                            appModel.immersiveSpaceState = .closed
                        }
                        
                    case .inTransition:
                        // This case should not ever happen because button is disabled for this case.
                        break
                    default:
                        break;
                    }
                }
            } label: {
                Text("Show Immersive Space")
            }
            .disabled(appModel.immersiveSpaceState == .inTransition)
            .animation(.none, value: 0)
            .fontWeight(.semibold)
            
        }
    }
}
