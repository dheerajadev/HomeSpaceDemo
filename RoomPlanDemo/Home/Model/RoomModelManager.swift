import Foundation
import RoomPlan
import SceneKit

struct StoredRoomModel: Codable {
    let name: String
    let fileName: String
    let createdAt: Date
    let roomData: Data  // Store raw room data
    
    var fileURL: URL {
        FileManager.default.documentDirectory
            .appendingPathComponent("Models")
            .appendingPathComponent(fileName)
    }
}

class RoomModelManager {
    
    static let shared = RoomModelManager()
    private let fileManager = FileManager.default
    
    public var modelsDirectory: URL {
        fileManager.documentDirectory
            .appendingPathComponent("Models", isDirectory: true)
    }
    
    private var metadataFile: URL {
        modelsDirectory.appendingPathComponent("metadata.json")
    }
    
    private init() {
        createModelsDirectoryIfNeeded()
    }
    
    private func createModelsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: modelsDirectory.path) {
            try? fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        }
    }
    
    func saveRoom(_ room: CapturedRoom, _ roomData: CapturedRoomData, name: String) throws {
        // Generate unique filename
        let fileName = "room_\(Date().timeIntervalSince1970).usdz"
        let fileURL = modelsDirectory.appendingPathComponent(fileName)
        
        // Export USDZ file
        try room.export(to: fileURL)
        
        // Convert CapturedRoomData to Data
        do {
            
            //let roomData = try JSONEncoder().encode(roomData) as Data
            //let roomData = try JSONEncoder().encode(room) as Data
            
            let encodedData = try JSONEncoder().encode(room) as Data
            
            // Create and save metadata
            let model = StoredRoomModel(
                name: name,
                fileName: fileName,
                createdAt: Date(),
                roomData: encodedData
            )
            
            var models = try loadMetadata()
            models.append(model)
            try saveMetadata(models)
            
        } catch {
            print("Error encoding room data: \(error)")
        }
    }
    
    func loadSavedModels() throws -> [SavedModel] {
        let metadata = try loadMetadata()
        
        return metadata.compactMap { model in
            let scene = try? SCNScene(url: model.fileURL, options: nil)
            
            // Convert Data back to CapturedRoomData
            guard let roomData = try? JSONDecoder().decode(CapturedStructure.self, from: model.roomData) else {
                return nil
            }
            
            return SavedModel(
                name: model.name,
                modelScene: scene,
                fileName: model.fileName,
                roomData: roomData
            )
        }
    }
    
    private func loadMetadata() throws -> [StoredRoomModel] {
        guard fileManager.fileExists(atPath: metadataFile.path) else { return [] }
        
        let data = try Data(contentsOf: metadataFile)
        return try JSONDecoder().decode([StoredRoomModel].self, from: data)
    }
    
    private func saveMetadata(_ models: [StoredRoomModel]) throws {
        let data = try JSONEncoder().encode(models)
        try data.write(to: metadataFile)
    }
    
    func deleteModel(_ fileName: String) throws {
        // Remove USDZ file
        let fileURL = modelsDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
        
        // Update metadata
        var models = try loadMetadata()
        models.removeAll { $0.fileName == fileName }
        try saveMetadata(models)
    }
}

// Model to hold saved room data
struct SavedModel {
    let name: String
    let modelScene: SCNScene?
    let fileName: String
    let roomData: CapturedStructure
}
