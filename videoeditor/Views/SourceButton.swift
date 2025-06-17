import SwiftUI

struct SourceButton: View {
    let text: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url) ?? URL(string: "https://example.com")!) {
            Text(text)
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
} 