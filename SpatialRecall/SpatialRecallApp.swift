import SwiftUI

@main
struct SpatialRecallApp: App {
    
    @State private var appModel = AppModel()
    @State private var avPlayerViewModel = AVPlayerViewModel()
    @StateObject private var roomTrackingManager = RoomTrackingManager()

    var body: some Scene {
        WindowGroup(id: appModel.imagePickerWindowID) {
            VStack {
                ImagePickerWindow()
                Spacer()
                ReactivateImmersiveSpaceButton()
            }
            .padding()
            .environment(appModel)
            .environmentObject(roomTrackingManager)
        }
        .defaultSize(width: 400, height: 300)
        .windowResizability(.contentSize)
        
        WindowGroup(id: appModel.textEditorWindowID) {
            VStack {
                TextArtefactWindow()
                Spacer()
                ReactivateImmersiveSpaceButton()
            }
            .padding()
            .environment(appModel)
            .environmentObject(roomTrackingManager)
        }
        .defaultSize(width: 400, height: 350)
        .windowResizability(.contentSize)
        
        WindowGroup(id: appModel.audioPickerWindowID) {
            VStack {
                AudioPickerWindow()
                Spacer()
                ReactivateImmersiveSpaceButton()
            }
            .padding()
            .environment(appModel)
            .environmentObject(roomTrackingManager)
        }
        .defaultSize(width: 400, height: 200)
        .windowResizability(.contentSize)
        
        WindowGroup(id: appModel.objectPickerWindowID) {
            VStack {
                ObjectPickerWindow()
                Spacer()
                ReactivateImmersiveSpaceButton()
            }
            .padding()
            .environment(appModel)
            .environmentObject(roomTrackingManager)
        }
        .defaultSize(width: 400, height: 200)
        .windowResizability(.contentSize)
        
        WindowGroup(id: appModel.videoPickerWindowID) {
            VStack {
                VideoPickerWindow()
                Spacer()
                ReactivateImmersiveSpaceButton()
            }
            .padding()
            .environment(appModel)
            .environmentObject(roomTrackingManager)
        }
        .defaultSize(width: 400, height: 300)
        .windowResizability(.contentSize)
        
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .environmentObject(roomTrackingManager)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                    avPlayerViewModel.play()
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    avPlayerViewModel.reset()
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
