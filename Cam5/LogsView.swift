import SwiftUI

struct LogsView: View {
    let logs: [CaptureLog]
    
    var body: some View {
        List(logs.reversed()) { log in
            VStack(alignment: .leading, spacing: 8) {
                Text(log.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let imageUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(log.filename),
                   let imageData = try? Data(contentsOf: imageUrl),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Capture History")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    NavigationView {
        LogsView(logs: [])
    }
} 