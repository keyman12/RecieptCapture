import SwiftUI

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let filename: String
    let status: String
}

struct LogsView: View {
    @State private var logs: [LogEntry] = []
    
    var body: some View {
        List(logs) { log in
            VStack(alignment: .center) {
                Text(log.filename)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                HStack {
                    Spacer()
                    Text(log.timestamp, style: .date)
                    Text(log.timestamp, style: .time)
                    Spacer()
                }
                .font(.subheadline)
                Text(log.status)
                    .foregroundColor(log.status == "Success" ? .green : .red)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Upload Logs")
                    .font(.largeTitle)
                    .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    NavigationView {
        LogsView()
    }
} 