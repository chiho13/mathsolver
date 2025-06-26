import SwiftUI

struct SearchResultsView: View {
    let searchOutput: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Scrollable content area
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    processContent(searchOutput)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
            }
            .background(Color.white.opacity(0.95))
        }
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    private func extractSource(from text: String) -> (String, String)? {
        let pattern = "\\(\\[(.*?)\\]\\((.*?)\\)\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        let sourceText = String(text[Range(match.range(at: 1), in: text)!])
        let sourceUrl = String(text[Range(match.range(at: 2), in: text)!])
        return (sourceText, sourceUrl)
    }
    
    private func processContent(_ text: String) -> some View {
        let cleanText = text
            .replacingOccurrences(of: "\\d+\\.\\d+,\\s*\\d+\\.\\d+", with: "", options: .regularExpression)
        
        if let (sourceText, sourceUrl) = extractSource(from: text) {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    FormattedText(text: cleanText.replacingOccurrences(of: "\\(\\[.*?\\]\\(.*?\\)\\)", with: "", options: .regularExpression))
                    SourceButton(text: sourceText, url: sourceUrl)
                }
            )
        } else {
            return AnyView(
                FormattedText(text: cleanText)
            )
        }
    }
} 