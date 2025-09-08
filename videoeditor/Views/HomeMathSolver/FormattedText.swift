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
        label.contentInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0) // Add padding to prevent clipping

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
    
    // Represents a parsed segment of the input text.
    private struct ContentSection: Identifiable, Hashable {
        let id = UUID()
        let title: String
        var parts: [ContentPart]

        static func == (lhs: ContentSection, rhs: ContentSection) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    @State private var sections: [ContentSection] = []

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

    // Represents a group of content parts (either inline or block).
    private struct ContentGroup: Identifiable, Hashable {
        let id = UUID()
        let isInline: Bool
        let parts: [ContentPart]

        static func == (lhs: ContentGroup, rhs: ContentGroup) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    /// A view that arranges its children in a horizontal flow, wrapping to new lines as needed.
    private struct FlowLayout: Layout {
        var spacing: CGFloat

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
            var totalHeight: CGFloat = 0
            var rowHeight: CGFloat = 0
            var currentRowWidth: CGFloat = 0

            guard let proposedWidth = proposal.width else { return .zero }

            for size in sizes {
                let requiredSpacing = currentRowWidth == 0 ? 0 : spacing
                if currentRowWidth + requiredSpacing + size.width > proposedWidth {
                    totalHeight += rowHeight + spacing
                    rowHeight = size.height
                    currentRowWidth = size.width
                } else {
                    currentRowWidth += requiredSpacing + size.width
                    rowHeight = max(rowHeight, size.height)
                }
            }
            totalHeight += rowHeight
            return CGSize(width: proposedWidth, height: totalHeight)
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

            var rows: [[(offset: Int, size: CGSize)]] = []
            var currentRow: [(offset: Int, size: CGSize)] = []
            var currentRowWidth: CGFloat = 0

            for (index, size) in sizes.enumerated() {
                let requiredSpacing = currentRow.isEmpty ? 0 : spacing
                if !currentRow.isEmpty && currentRowWidth + requiredSpacing + size.width > bounds.width {
                    rows.append(currentRow)
                    currentRow = []
                    currentRowWidth = 0
                }
                
                currentRow.append((offset: index, size: size))
                currentRowWidth += (currentRow.count == 1 ? 0 : spacing) + size.width
            }
            if !currentRow.isEmpty {
                rows.append(currentRow)
            }

            var y = bounds.minY
            for row in rows {
                let rowHeight = row.map { $0.size.height }.max() ?? 0
                var x = bounds.minX

                for item in row {
                    let subview = subviews[item.offset]
                    // Center vertically in the current row
                    let verticalOffset = (rowHeight - item.size.height) / 2.0
                    subview.place(
                        at: CGPoint(x: x, y: y + verticalOffset),
                        anchor: .topLeading,
                        proposal: .unspecified
                    )
                    x += item.size.width + spacing
                }
                y += rowHeight + spacing
            }
        }
    }

    /// Groups content parts into inline and block-level groups.
    private func groupParts(from parts: [ContentPart]) -> [ContentGroup] {
        var groups: [ContentGroup] = []
        var currentInlineGroup: [ContentPart] = []

        for part in parts {
            if part.type == .blockLatex {
                if !currentInlineGroup.isEmpty {
                    groups.append(ContentGroup(isInline: true, parts: currentInlineGroup))
                    currentInlineGroup = []
                }
                groups.append(ContentGroup(isInline: false, parts: [part]))
            } else {
                currentInlineGroup.append(part)
            }
        }

        if !currentInlineGroup.isEmpty {
            groups.append(ContentGroup(isInline: true, parts: currentInlineGroup))
        }

        return groups
    }

    /// Parses the input text into an array of `ContentPart`s.
    private func parseContentToParts(from textToParse: String) -> [ContentPart] {
        var parts: [ContentPart] = []
        var lastEnd: String.Index = textToParse.startIndex
        
        do {
            // Updated regex to handle lists better by not including newline in a match,
            // which prevents splitting a list item across multiple MarkdownUI views.
            let regex = try NSRegularExpression(pattern: #"(\$\$[\s\S]*?\$\$|\$[\s\S]*?\$)"#)
            let matches = regex.matches(in: textToParse, range: NSRange(textToParse.startIndex..., in: textToParse))
            
            for match in matches {
                if let range = Range(match.range, in: textToParse) {
                    // Add the Markdown text that comes before the LaTeX block.
                    if range.lowerBound > lastEnd {
                        let markdownText = String(textToParse[lastEnd..<range.lowerBound])
                        // Handle cases where a period or comma is part of the text
                        let periodCheck = markdownText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !periodCheck.isEmpty {
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

    private func parseText(from textToParse: String) {
        var parsedSections: [ContentSection] = []
        
        // Split by "##" that follows a newline, ensuring we capture the "##" as part of the title.
        let components = textToParse.replacingOccurrences(of: "\n## ", with: "\n<SECTION_DELIMITER>## ")
                                    .components(separatedBy: "\n<SECTION_DELIMITER>")
        
        for (index, component) in components.enumerated() {
            guard !component.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            
            if index == 0 && !component.hasPrefix("## ") {
                // This is the initial content before the first heading, or the whole text if no headings.
                let contentParts = parseContentToParts(from: component)
                if !contentParts.isEmpty {
                    parsedSections.append(ContentSection(title: "", parts: contentParts))
                }
            } else {
                let lines = component.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                let title = String(lines.first ?? "")
                let content = lines.count > 1 ? String(lines.dropFirst().joined(separator: "\n")) : ""
                
                let contentParts = parseContentToParts(from: content)
                parsedSections.append(ContentSection(title: title, parts: contentParts))
            }
        }

        self.sections = parsedSections
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
                    .markdownMargin(bottom: 12)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .listItem { configuration in
                configuration.label
                    .lineSpacing(8)
            }
    }

    private var inlineMarkdownTheme: Theme {
        Theme()
            .text {
                FontSize(18)
                ForegroundColor(.primary)
            }
            .paragraph { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true) // Allow Markdown to take its natural height
                    .multilineTextAlignment(.leading)
            }
            .listItem { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sections, id: \.self) { section in
                // Render section title if it exists
                if !section.title.isEmpty {
                    Markdown(section.title)
                        .markdownTheme(markdownTheme)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20) // Apply horizontal padding to align with content blocks
                }
                
                let groupedParts = groupParts(from: section.parts)
                
                if !groupedParts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(groupedParts, id: \.self) { group in
                            if group.isInline {
                                FlowLayout(spacing: 4) {
                                    ForEach(group.parts, id: \.self) { part in
                                        switch part.type {
                                        case .markdown:
                                            Markdown(part.value)
                                                .markdownTheme(inlineMarkdownTheme)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                        case .inlineLatex:
                                            MathLabel(latex: part.value, mode: .text)
                                                .fixedSize(horizontal: false, vertical: true)
                                        default:
                                            EmptyView()
                                        }
                                    }
                                }
                            } else {
                                // Block LaTeX is centered
                                let part = group.parts.first!
                                MathLabel(latex: part.value, mode: .display)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 10)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .opacity(isRendered ? 1 : 0)
        .task(id: text) {
            isRendered = false
            parseText(from: text)
            // A short delay to allow the view hierarchy to update before fading in
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            withAnimation {
                isRendered = true
            }
        }
    }
}