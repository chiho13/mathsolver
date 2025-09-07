import SwiftUI
import SwiftMath
import MarkdownUI

/// A SwiftUI wrapper for MTMathUILabel that can handle display and text modes.
struct MathLabel: UIViewRepresentable {
    var latex: String
    var mode: MTMathUILabelMode

    func makeUIView(context: Context) -> MTMathUILabel {
        let label = MTMathUILabel()
        label.fontSize = 18 // Harmonized font size
        label.font = MTFontManager().xitsFont(withSize: 18) // Harmonized font size
        label.textColor = .label
        label.textAlignment = .left
        label.labelMode = mode
        label.latex = latex
        // For dynamic height in SwiftUI
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ uiView: MTMathUILabel, context: Context) {
        uiView.latex = latex
        uiView.labelMode = mode
    }
}

/// A view that displays a mix of Markdown and LaTeX text with improved styling.
struct FormattedText: View {
    let text: String
    @State private var parts: [ContentPart] = []
    @State private var isRendered = false

    // Defines the different types of content parts.
    private enum ContentType {
        case markdown
        case inlineLatex
        case blockLatex
    }

    // Represents a parsed segment of the input text.
    private struct ContentPart: Identifiable, Hashable {
        let id = UUID()
        let value: String
        let type: ContentType
    }

    /// Parses the input text into an array of `ContentPart`s.
    private func parseText(from textToParse: String) -> [ContentPart] {
        var parts: [ContentPart] = []
        var lastEnd: String.Index = textToParse.startIndex
        
        do {
            // This regex finds all instances of $$...$$ or $...$
            let regex = try NSRegularExpression(pattern: #"(\$\$[\s\S]*?\$\$|\$[\s\S]*?\$)"#)
            let matches = regex.matches(in: textToParse, range: NSRange(textToParse.startIndex..., in: textToParse))
            
            for match in matches {
                if let range = Range(match.range, in: textToParse) {
                    // Add the Markdown text that comes before the LaTeX block.
                    if range.lowerBound > lastEnd {
                        let markdownText = String(textToParse[lastEnd..<range.lowerBound])
                        if !markdownText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            parts.append(ContentPart(value: markdownText, type: .markdown))
                        }
                    }
                    
                    // Add the LaTeX part, determining if it's inline or block.
                    var latex = String(textToParse[range])
                    if latex.hasPrefix("$$") {
                        latex.removeFirst(2)
                        latex.removeLast(2)
                        parts.append(ContentPart(value: latex, type: .blockLatex))
                    } else {
                        latex.removeFirst()
                        latex.removeLast()
                        parts.append(ContentPart(value: latex, type: .inlineLatex))
                    }
                    
                    lastEnd = range.upperBound
                }
            }
            
            // Add any remaining Markdown text after the last LaTeX block.
            if lastEnd < textToParse.endIndex {
                let markdownText = String(textToParse[lastEnd...])
                if !markdownText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    parts.append(ContentPart(value: markdownText, type: .markdown))
                }
            }
        } catch {
            // If regex fails for any reason, treat the entire text as Markdown.
            parts.append(ContentPart(value: textToParse, type: .markdown))
        }
        
        return parts
    }
    
    // A custom theme for Markdown rendering to ensure consistency and style.
    private var markdownTheme: Theme {
        Theme()
            .text {
                FontSize(18)
                ForegroundColor(.primary)
            }
            .heading2 { configuration in // Corrected: Style for ## headers using .heading2
                configuration.label
                    .markdownTextStyle {
                        FontWeight(.semibold)
                        FontSize(20) // Reduced size for a less imposing look
                    }
                    .markdownMargin(top: 8, bottom: 4) // Corrected: Use .markdownMargin for spacing
            }
            .paragraph { configuration in
                configuration.label
                    .lineSpacing(5)
                    .markdownMargin(bottom: 16)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(parts, id: \.self) { part in
                switch part.type {
                case .markdown:
                    Markdown(part.value)
                        .markdownTheme(markdownTheme)
                case .inlineLatex:
                    MathLabel(latex: part.value, mode: .text)
                        .fixedSize(horizontal: false, vertical: true)
                case .blockLatex:
                    MathLabel(latex: part.value, mode: .display)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                }
            }
        }
        .opacity(isRendered ? 1 : 0)
        .task(id: text) {
            isRendered = false
            parts = parseText(from: text)
            // A short delay to allow the view hierarchy to update before fading in
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            withAnimation {
                isRendered = true
            }
        }
    }
}
