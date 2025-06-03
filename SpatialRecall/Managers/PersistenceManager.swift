//
//  PersistencyManager.swift
//  SpatialRecall
//
//  Created by Lorenz Bernert on 01.06.25.
//

import RealityKit
import SwiftUI
import struct PhotosUI.PhotosPickerItem
import AVKit
import ARKit
import Foundation

enum ArtefactType: String, Codable, CaseIterable {
    case image, video, audio, text, object
}
struct PersistentArtefact: Codable, Identifiable {
    let id: UUID
    let worldAnchor: UUID
    let type: ArtefactType
    var data: ArtefactData
    var position: SIMD3<Float>
    var orientation: CodableQuatf
    var scale: SIMD3<Float>
}

struct ArtefactData: Codable {
    let imageAssetID: String?
    let videoID: String?
    let audioURL: URL?
    let objectID: String?
    var textContent: String?
    
    init(imageAssetID: String? = nil, videoID: String? = nil, audioURL: URL? = nil,
         objectID: String? = nil, textContent: String? = nil) {
        self.imageAssetID = imageAssetID
        self.videoID = videoID
        self.audioURL = audioURL
        self.objectID = objectID
        self.textContent = textContent
    }
}

struct CodableQuatf: Codable {
    let values: [Float] // [x, y, z, w] representing simd_quatf

    init(from quat: simd_quatf) {
        self.values = [quat.imag.x, quat.imag.y, quat.imag.z, quat.real]
    }

    var simdQuat: simd_quatf {
        return simd_quatf(ix: values[0], iy: values[1], iz: values[2], r: values[3])
    }
}

struct CodableTransform: Codable {
    let matrix: [Float] // 16 elements representing simd_float4x4
    
    init(from transform: simd_float4x4) {
        self.matrix = [
            transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w,
            transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w,
            transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w,
            transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w
        ]
    }
    
    var simdTransform: simd_float4x4 {
        return simd_float4x4(
            simd_float4(matrix[0], matrix[1], matrix[2], matrix[3]),
            simd_float4(matrix[4], matrix[5], matrix[6], matrix[7]),
            simd_float4(matrix[8], matrix[9], matrix[10], matrix[11]),
            simd_float4(matrix[12], matrix[13], matrix[14], matrix[15])
        )
    }
}

class PersistenceManager {
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    var artefactsFileURL: URL {
        documentsDirectory.appendingPathComponent("persistent_artefacts.json")
    }
    
    
    func saveArtefacts(_ artefacts: [PersistentArtefact]) {
        do {
            let data = try JSONEncoder().encode(artefacts)
            try data.write(to: artefactsFileURL)
            print("Artefacts saved successfully")
        } catch {
            print("Failed to save artefacts: \(error)")
        }
    }
    
    func loadArtefacts() -> [PersistentArtefact] {
        do {
            let data = try Data(contentsOf: artefactsFileURL)
            let artefacts = try JSONDecoder().decode([PersistentArtefact].self, from: data)
            print("Loaded \(artefacts.count) artefacts")
            return artefacts
        } catch {
            print("Failed to load artefacts: \(error)")
            return []
        }
    }
    
    func loadDemoArtefacts() -> [PersistentArtefact] {
        do {
            guard let url = Bundle.main.url(forResource: "demo", withExtension: "json") else {
                print( "File 'demo.json' not found" )
                return []
            }
            let data = try Data(contentsOf: url)
            let artefacts = try JSONDecoder().decode([PersistentArtefact].self, from: data)
            print("Loaded \(artefacts.count) artefacts")
            return artefacts
        } catch {
            print("Failed to load artefacts: \(error)")
            return []
        }
    }
    
    func clearAllArtefacts() {
        do {
            try FileManager.default.removeItem(at: artefactsFileURL)
            deleteAllStoredMedia()
            print("All artefacts cleared")
        } catch {
            print("Failed to clear artefacts: \(error)")
        }
    }
    
    func deleteMedia(mediaID: String?) {
        guard let id = mediaID else { return }
        deleteImage(imageID: id)
        deleteVideo(videoID: id)
        deleteObject(objectID: id)
    }
    
    // Save image and return persistent identifier
    func saveImage(data: Data) -> String? {
        let imageID = UUID().uuidString
        let imageURL = documentsDirectory.appendingPathComponent("\(imageID).jpg")
        
        do {
            try data.write(to: imageURL)
            return imageID
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    // Load image data from persistent storage
    func loadImageData(imageID: String) -> Data? {
        let imageURL = documentsDirectory.appendingPathComponent("\(imageID).jpg")
        return try? Data(contentsOf: imageURL)
    }
    
    // Load UIImage from persistent storage
    func loadImage(imageID: String) -> UIImage? {
        guard let data = loadImageData(imageID: imageID) else { return nil }
        return UIImage(data: data)
    }
    
    // Delete image from storage
    func deleteImage(imageID: String) {
        let imageURL = documentsDirectory.appendingPathComponent("\(imageID).jpg")
        try? FileManager.default.removeItem(at: imageURL)
    }
    
    // MARK: - Video Methods
    
    // Save video and return persistent identifier
    func saveVideo(from sourceURL: URL) -> String? {
        let videoID = UUID().uuidString
        let fileExtension = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension
        let destinationURL = documentsDirectory.appendingPathComponent("\(videoID).\(fileExtension)")
        
        do {
            // Copy the video file to documents directory
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return videoID
        } catch {
            print("Failed to save video: \(error)")
            return nil
        }
    }
    
    // Get persistent URL for video
    func getVideoURL(videoID: String) -> URL? {
        // Try common video extensions
        let extensions = ["mp4", "mov", "m4v", "avi"]
        
        for ext in extensions {
            let videoURL = documentsDirectory.appendingPathComponent("\(videoID).\(ext)")
            if FileManager.default.fileExists(atPath: videoURL.path) {
                return videoURL
            }
        }
        
        print("Video file not found for ID: \(videoID)")
        return nil
    }
    
    // Delete video from storage
    func deleteVideo(videoID: String) {
        let extensions = ["mp4", "mov", "m4v", "avi"]
        
        for ext in extensions {
            let videoURL = documentsDirectory.appendingPathComponent("\(videoID).\(ext)")
            if FileManager.default.fileExists(atPath: videoURL.path) {
                try? FileManager.default.removeItem(at: videoURL)
                break
            }
        }
    }
    
    // MARK: - 3D Object Methods
        
    // Save 3D object and return persistent identifier
    func saveObject(from sourceURL: URL) -> String? {
        let objectID = UUID().uuidString
        let fileExtension = sourceURL.pathExtension.isEmpty ? "usdz" : sourceURL.pathExtension
        let destinationURL = documentsDirectory.appendingPathComponent("\(objectID).\(fileExtension)")
        
        do {
            // Copy the 3D object file to documents directory
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return objectID
        } catch {
            print("Failed to save 3D object: \(error)")
            return nil
        }
    }
    
    // Get persistent URL for 3D object
    func getObjectURL(objectID: String) -> URL? {
        // Try common 3D object extensions
        let extensions = ["obj", "stl", "ply", "usdz"]
        
        for ext in extensions {
            let objectURL = documentsDirectory.appendingPathComponent("\(objectID).\(ext)")
            if FileManager.default.fileExists(atPath: objectURL.path) {
                return objectURL
            }
        }
        
        print("3D object file not found for ID: \(objectID)")
        return nil
    }
    
    // Delete 3D object from storage
    func deleteObject(objectID: String) {
        let extensions = ["obj", "stl", "ply", "usdz"]
        
        for ext in extensions {
            let objectURL = documentsDirectory.appendingPathComponent("\(objectID).\(ext)")
            if FileManager.default.fileExists(atPath: objectURL.path) {
                try? FileManager.default.removeItem(at: objectURL)
                break
            }
        }
    }
        
    // Delete ALL stored media files
    func deleteAllStoredMedia() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory,
                                                                      includingPropertiesForKeys: nil,
                                                                      options: [])
            
            for fileURL in fileURLs {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    print("Deleted: \(fileURL.lastPathComponent)")
                } catch {
                    print("Failed to delete \(fileURL.lastPathComponent): \(error)")
                }
            }
            
            print("All stored media files deleted successfully")
        } catch {
            print("Failed to enumerate files in documents directory: \(error)")
        }
    }
    
}
