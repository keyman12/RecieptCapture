import SwiftUI
import UIKit

class ImageCapture: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var showingImagePicker = false
    @Published var logs: [CaptureLog] = []
    
    func saveImage(_ image: UIImage) {
        capturedImage = image
        
        // Save to documents directory
        if let data = image.jpegData(compressionQuality: 0.8) {
            let timestamp = Date()
            let filename = getDocumentsDirectory().appendingPathComponent("\(timestamp.ISO8601Format()).jpg")
            
            try? data.write(to: filename)
            
            // Add to logs
            let log = CaptureLog(timestamp: timestamp, filename: filename.lastPathComponent)
            logs.append(log)
            
            // Save logs
            saveLogs()
        }
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func saveLogs() {
        if let data = try? JSONEncoder().encode(logs) {
            let filename = getDocumentsDirectory().appendingPathComponent("capture_logs.json")
            try? data.write(to: filename)
        }
    }
    
    func loadLogs() {
        let filename = getDocumentsDirectory().appendingPathComponent("capture_logs.json")
        if let data = try? Data(contentsOf: filename) {
            if let decodedLogs = try? JSONDecoder().decode([CaptureLog].self, from: data) {
                logs = decodedLogs
            }
        }
    }
}

struct CaptureLog: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let filename: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
} 