//
//  ArtefactHudButton.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 02.05.25.
//
import SwiftUI
import RealityKit

struct ArtefactHudButton: View {
    @StateObject private var artefactManager = ArtefactManager.shared
    @State private var isTextInput: Bool = false
    @State private var textInput: String = ""
    
    var body: some View {
        RealityView { content, attachments in
            
            let headAnchor = AnchorEntity(.head)
            headAnchor.position = [0, -0.1, -0.5]
            content.add(headAnchor)
            
            guard let textInputAttachment = attachments.entity(for: "TextInputBox") else { return }
            textInputAttachment.components.set(BillboardComponent())
            headAnchor.addChild(textInputAttachment)
                                    
            // Check if running on actual device vs simulator/preview
            let isRunningOnDevice = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] == nil        
            
            guard let hudAttachment = attachments.entity(for: "HUD") else { return }
            
            if isRunningOnDevice {
                // Running on actual Apple Vision Pro - attach HUD to palm
                let palmAnchor = AnchorEntity(.hand(.left, location: .palm))
                palmAnchor.position = [0, 0, 0.2] // Slightly next to palm
                let rotationX = simd_quatf(angle: -Float.pi/2, axis: [1, 0, 0])
                let rotationZ = simd_quatf(angle: Float.pi/2, axis: [0, 0, 1])
                let rotation3 = simd_quatf(angle: Float.pi, axis: [1, 0, 0])
                let rotation4 = simd_quatf(angle: Float.pi, axis: [0, 1, 0])
                let rotation5 = simd_quatf(angle: -Float.pi/10, axis: [0, 1, 0])
                let rotation6 = simd_quatf(angle: Float.pi/8, axis: [1, 0, 0])
                palmAnchor.orientation = rotationX * rotationZ * rotation3 * rotation4 * rotation5 * rotation6
                content.add(palmAnchor)
                palmAnchor.addChild(hudAttachment)
            } else {
                // Running in Simulator/Preview - attach HUD to head anchor
                hudAttachment.position = [0, -0.2, 0]
                headAnchor.addChild(hudAttachment)
            }
            
        } attachments: {
            Attachment(id: "TextInputBox") {
                if isTextInput {
                    TextInputBox(
                        isTextInput: $isTextInput,
                        textInput: $textInput,
                    )
                }
            }
            Attachment(id: "HUD") {
                VStack(spacing: 10) {
                    if !artefactManager.isErasing {
                        HStack(spacing: 8) {
                            AddBoxArtefact()
                            AddImageArtefact()
                            AddTextArtefact(isTextInput: $isTextInput, textInput: $textInput)
                            AddAudioArtefact()
                            AddObjectArtefact()
                            AddVideoArtefact()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                                    
                    ModeToggle(isErasing: $artefactManager.isErasing)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CreationButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.thinMaterial))
                Text(label)
                    .font(.system(size: 12))
            }.padding(.bottom, 5)
        }
        .labelStyle(.titleAndIcon)        
        .buttonStyle(.plain)
        .padding(3)
        .background(Capsule().fill(.ultraThinMaterial))
    }
}

struct ModeToggle: View {
    @Binding var isErasing: Bool
    @Namespace private var toggleNamespace
    
    var body: some View {
        HStack(spacing: 2) {
            ToggleOption(
                icon: "pencil",
                label: "Create",
                isSelected: !isErasing,
                action: { isErasing = false }
            )
            ToggleOption(
                icon: "eraser",
                label: "Delete",
                isSelected: isErasing,
                action: { isErasing = true }
            )
        }
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .padding(8)
        .background(.regularMaterial)
        .clipShape(Capsule())
    }
}

struct ToggleOption: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(label)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color.accentColor)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .clipShape(Capsule())
    }
}
