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
        
        // Further split paragraphs and group list items
        var result: [String] = []
        for paragraph in paragraphs {
            let lines = paragraph.components(separatedBy: "\n")
            var currentGroup: [String] = []
            var currentListItems: [String] = []
            var currentListType: String? = nil // "unordered" or "ordered"
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Check if this line is a header
                if trimmedLine.range(of: #"^#{1,6}\s+"#, options: .regularExpression) != nil {
                    // Flush any current content
                    flushCurrentContent(&result, &currentGroup, &currentListItems, &currentListType)
                    // Add the header as its own item
                    result.append(trimmedLine)
                }
                // Check if this line is an unordered list item
                else if trimmedLine.range(of: #"^[-*+]\s+"#, options: .regularExpression) != nil {
                    // If we were building a different type of list or regular content, flush it
                    if currentListType != "unordered" {
                        flushCurrentContent(&result, &currentGroup, &currentListItems, &currentListType)
                        currentListType = "unordered"
                    }
                    currentListItems.append(trimmedLine)
                }
                // Check if this line is an ordered list item
                else if trimmedLine.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil {
                    // If we were building a different type of list or regular content, flush it
                    if currentListType != "ordered" {
                        flushCurrentContent(&result, &currentGroup, &currentListItems, &currentListType)
                        currentListType = "ordered"
                    }
                    currentListItems.append(trimmedLine)
                }
                else if !trimmedLine.isEmpty {
                    // Regular content - flush any current list
                    if !currentListItems.isEmpty {
                        flushCurrentContent(&result, &currentGroup, &currentListItems, &currentListType)
                    }
                    // Add non-header, non-list content to current group
                    currentGroup.append(trimmedLine)
                }
            }
            
            // Add any remaining content
            flushCurrentContent(&result, &currentGroup, &currentListItems, &currentListType)
        }
        
        print("Processed paragraphs: \(result)") // Debug: Log paragraphs
        return result
    }
    
    private func flushCurrentContent(_ result: inout [String], _ currentGroup: inout [String], _ currentListItems: inout [String], _ currentListType: inout String?) {
        // Add any accumulated regular content
        if !currentGroup.isEmpty {
            result.append(currentGroup.joined(separator: "\n"))
            currentGroup = []
        }
        
        // Add any accumulated list items as a single block
        if !currentListItems.isEmpty {
            let listMarker = currentListType == "ordered" ? "ORDERED_LIST:" : "UNORDERED_LIST:"
            result.append(listMarker + currentListItems.joined(separator: "\n"))
            currentListItems = []
            currentListType = nil
        }
    }
    
    private func processMarkdownParagraph(_ text: String) -> AnyView {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Processing paragraph: '\(trimmedText)'") // Debug: Log input
        
        // Check for list blocks first
        if trimmedText.hasPrefix("UNORDERED_LIST:") {
            let listContent = String(trimmedText.dropFirst("UNORDERED_LIST:".count))
            return AnyView(processUnorderedList(listContent))
        }
        
        if trimmedText.hasPrefix("ORDERED_LIST:") {
            let listContent = String(trimmedText.dropFirst("ORDERED_LIST:".count))
            return AnyView(processOrderedList(listContent))
        }
        
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
            return AnyView(Text(createStyledAttributedString(text)))
        }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        
        if matches.isEmpty {
            return AnyView(Text(createStyledAttributedString(text)))
        }
        
        // Create a flowing text layout that wraps properly
        return AnyView(
            Text(createAttributedStringWithLinks(text: text, matches: matches))
                .environment(\.openURL, OpenURLAction { url in
                    UIApplication.shared.open(url)
                    return .handled
                })
        )
    }
    
    private func createAttributedStringWithLinks(text: String, matches: [NSTextCheckingResult]) -> AttributedString {
        var result = AttributedString()
        let nsText = text as NSString
        var lastIndex = 0
        
        for match in matches {
            let range = match.range
            let linkTextRange = match.range(at: 1)
            let urlRange = match.range(at: 2)
            
            // Add text before the link
            if range.location > lastIndex {
                let before = nsText.substring(with: NSRange(location: lastIndex, length: range.location - lastIndex))
                if !before.isEmpty {
                    result += createStyledAttributedString(before)
                }
            }
            
            // Add the link
            let linkText = nsText.substring(with: linkTextRange)
            let urlString = nsText.substring(with: urlRange)
            
            if let url = URL(string: urlString) {
                var linkAttributedString = createStyledAttributedString(linkText)
                linkAttributedString.foregroundColor = .blue
                linkAttributedString.underlineStyle = .single
                linkAttributedString.link = url
                result += linkAttributedString
            } else {
                // If URL is invalid, just show the markdown syntax
                result += createStyledAttributedString("[\(linkText)](\(urlString))")
            }
            
            lastIndex = range.location + range.length
        }
        
        // Add remaining text
        if lastIndex < nsText.length {
            let after = nsText.substring(from: lastIndex)
            if !after.isEmpty {
                result += createStyledAttributedString(after)
            }
        }
        
        return result
    }
    
    private func createStyledAttributedString(_ text: String) -> AttributedString {
        var result = AttributedString(text)
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
        
        matches.sort { $0.range.location > $1.range.location } // Process from end to start to maintain indices
        
        // Apply styling from end to start to preserve string indices
        for match in matches {
            let swiftRange = Range(match.range, in: text)!
            let contentSwiftRange = Range(match.contentRange, in: text)!
            
            let styledContent = String(text[contentSwiftRange])
            var styledAttributedString = AttributedString(styledContent)
            
            if match.type == "bold" {
                styledAttributedString.font = .body.bold()
            } else if match.type == "italic" {
                styledAttributedString.font = .body.italic()
            }
            
            // Replace the original markdown with styled content
            let attributedRange = AttributedString.Index(swiftRange.lowerBound, within: result)!..<AttributedString.Index(swiftRange.upperBound, within: result)!
            result.replaceSubrange(attributedRange, with: styledAttributedString)
        }
        
        return result
    }
    

    
    private func processUnorderedList(_ listContent: String) -> some View {
        let items = listContent.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<items.count, id: \.self) { index in
                let item = items[index]
                // Remove the list marker (-, *, or +) and process the content
                let content = item.replacingOccurrences(of: #"^[-*+]\s+"#, with: "", options: .regularExpression)
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.body)
                        .foregroundColor(.primary)
                    processLineWithLinks(content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.leading, 16)
    }
    
    private func processOrderedList(_ listContent: String) -> some View {
        let items = listContent.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<items.count, id: \.self) { index in
                let item = items[index]
                // Remove the list marker (1., 2., etc.) and process the content
                let content = item.replacingOccurrences(of: #"^\d+\.\s+"#, with: "", options: .regularExpression)
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(minWidth: 20, alignment: .trailing)
                    processLineWithLinks(content)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.leading, 16)
    }
}

#Preview {
    FormattedText(text: """
    # Header 1
    ## Header 2
    ### Header 3
    
    This is a paragraph with **bold** and *italic* text.
    
    [Duck Duck Go](https://duckduckgo.com)
    
    - Unordered list item 1
    - Unordered list item 2
    - Unordered list item 3
    
    1. Ordered list item 1
    2. Ordered list item 2
    3. Ordered list item 3
    
    * Alternative bullet style
    + Another bullet style
    """)
}