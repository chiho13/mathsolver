import SwiftUI

struct FormattedText: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(processText(text), id: \.self) { paragraph in
                processMarkdownParagraph(paragraph)
            }
        }
    }
    
    private func processText(_ text: String) -> [String] {
        // Split on double newlines first
        let paragraphs = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Further split paragraphs that contain multiple headers
        var result: [String] = []
        for paragraph in paragraphs {
            let lines = paragraph.components(separatedBy: "\n")
            var currentGroup: [String] = []
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                // Check if this line is a header
                if trimmedLine.range(of: #"^#{1,6}\s+"#, options: .regularExpression) != nil {
                    // If we have accumulated non-header content, add it as a group
                    if !currentGroup.isEmpty {
                        result.append(currentGroup.joined(separator: "\n"))
                        currentGroup = []
                    }
                    // Add the header as its own item
                    result.append(trimmedLine)
                } else if !trimmedLine.isEmpty {
                    // Add non-header content to current group
                    currentGroup.append(trimmedLine)
                }
            }
            
            // Add any remaining content
            if !currentGroup.isEmpty {
                result.append(currentGroup.joined(separator: "\n"))
            }
        }
        
        print("Processed paragraphs: \(result)") // Debug: Log paragraphs
        return result
    }
    
    private func processMarkdownParagraph(_ text: String) -> AnyView {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Processing paragraph: '\(trimmedText)'") // Debug: Log input
        
        // Regex: 1-6 hashes, required space, optional content
        let headerPattern = #"^(#{1,6})\s+(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: headerPattern, options: []) else {
            print("Regex compilation failed")
            return processLineWithLinks(trimmedText)
        }
        
        let nsText = trimmedText as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: trimmedText, range: range)
        
        if let match = matches.first {
            let hashRange = match.range(at: 1)
            let hashCount = nsText.substring(with: hashRange).count
            
            // Get content (capture group 2) - will be empty string if no content after space
            let contentRange = match.range(at: 2)
            let content = nsText.substring(with: contentRange)
            
            print("Header detected: \(hashCount) hashes, content: '\(content)'") // Debug: Log match
            
            // Process header content for inline markdown
            let styled = processLineWithLinks(content)
            
            // Apply header styling
            switch hashCount {
            case 1: return AnyView(styled.font(.system(size: 32, weight: .bold)))
            case 2: return AnyView(styled.font(.system(size: 26, weight: .bold)))
            case 3: return AnyView(styled.font(.system(size: 22, weight: .bold)))
            case 4: return AnyView(styled.font(.system(size: 18, weight: .bold)))
            case 5: return AnyView(styled.font(.system(size: 16, weight: .bold)))
            case 6: return AnyView(styled.font(.system(size: 14, weight: .bold)))
            default: return AnyView(styled.font(.body))
            }
        }
        
        print("No header match, processing as text: '\(trimmedText)'") // Debug: Log fallback
        return processLineWithLinks(trimmedText)
    }
    
    private func processLineWithLinks(_ text: String) -> AnyView {
        let linkPattern = #"\[(.*?)\]\((.*?)\)"#
        guard let regex = try? NSRegularExpression(pattern: linkPattern) else {
            print("Link regex failed")
            return AnyView(styledText(text))
        }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        
        if matches.isEmpty {
            return AnyView(styledText(text))
        }
        
        var views: [AnyView] = []
        var lastIndex = 0
        for match in matches {
            let range = match.range
            let linkTextRange = match.range(at: 1)
            let urlRange = match.range(at: 2)
            
            if range.location > lastIndex {
                let before = nsText.substring(with: NSRange(location: lastIndex, length: range.location - lastIndex))
                if !before.isEmpty {
                    views.append(AnyView(styledText(before)))
                }
            }
            
            let linkText = nsText.substring(with: linkTextRange)
            let urlString = nsText.substring(with: urlRange)
            if let url = URL(string: urlString) {
                views.append(AnyView(
                    Button(action: {
                        UIApplication.shared.open(url)
                    }) {
                        Text(linkText)
                            .foregroundColor(.blue)
                            .underline()
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.1))
                                    .padding(-2)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                ))
            } else {
                views.append(AnyView(styledText("[\(linkText)](\(urlString))")))
            }
            lastIndex = range.location + range.length
        }
        
        if lastIndex < nsText.length {
            let after = nsText.substring(from: lastIndex)
            if !after.isEmpty {
                views.append(AnyView(styledText(after)))
            }
        }
        
        return AnyView(HStack(spacing: 0) {
            ForEach(0..<views.count, id: \.self) { i in
                views[i]
            }
        })
    }
    
    private func styledText(_ text: String) -> Text {
        var result = Text("")
        let nsText = text as NSString
        
        let boldPattern = #"\*\*(.*?)\*\*"#
        let italicAsteriskPattern = #"(?<!\*)\*(?!\*)([^*]+)\*(?!\*)"#
        let italicUnderscorePattern = #"_([^_]+)_"#
        
        var matches: [(range: NSRange, contentRange: NSRange, type: String)] = []
        
        if let boldRegex = try? NSRegularExpression(pattern: boldPattern) {
            boldRegex.enumerateMatches(in: text, range: NSRange(location: 0, length: nsText.length)) { (match, _, _) in
                if let match = match {
                    matches.append((match.range, match.range(at: 1), "bold"))
                }
            }
        }
        
        if let italicAsteriskRegex = try? NSRegularExpression(pattern: italicAsteriskPattern) {
            italicAsteriskRegex.enumerateMatches(in: text, range: NSRange(location: 0, length: nsText.length)) { (match, _, _) in
                if let match = match {
                    matches.append((match.range, match.range(at: 1), "italic"))
                }
            }
        }
        
        if let italicUnderscoreRegex = try? NSRegularExpression(pattern: italicUnderscorePattern) {
            italicUnderscoreRegex.enumerateMatches(in: text, range: NSRange(location: 0, length: nsText.length)) { (match, _, _) in
                if let match = match {
                    matches.append((match.range, match.range(at: 1), "italic"))
                }
            }
        }
        
        matches.sort { $0.range.location < $1.range.location }
        
        var currentOffset = 0
        
        for match in matches {
            if match.range.location > currentOffset {
                let plainText = nsText.substring(with: NSRange(location: currentOffset, length: match.range.location - currentOffset))
                result = result + Text(plainText)
            }
            
            let styledContent = nsText.substring(with: match.contentRange)
            if match.type == "bold" {
                result = result + Text(styledContent).bold()
            } else if match.type == "italic" {
                result = result + Text(styledContent).italic()
            }
            
            currentOffset = match.range.location + match.range.length
        }
        
        if currentOffset < nsText.length {
            let remainingText = nsText.substring(from: currentOffset)
            result = result + Text(remainingText)
        }
        
        return result
    }
}

#Preview {
    FormattedText(text: """
    # Header 1
    ## Header 2
    ### Header 3
    
    This is a paragraph with **bold** and *italic* text.
    
    [Duck Duck Go](https://duckduckgo.com)
    
    - List item 1
    - List item 2
    """)
}