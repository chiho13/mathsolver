import SwiftUI
import UIKit

struct ContentView: View {
    @State private var query: String = ""
    @State private var results: [SearchResult] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @StateObject private var searchService = SearchAPIService()
    @State private var searchOutput: String? = nil
    @StateObject private var locationManager = LocationManager()
    
    func extractSource(from text: String) -> (String, String)? {
        let pattern = "\\(\\[(.*?)\\]\\((.*?)\\)\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        let sourceText = String(text[Range(match.range(at: 1), in: text)!])
        let sourceUrl = String(text[Range(match.range(at: 2), in: text)!])
        return (sourceText, sourceUrl)
    }
    
    func processContent(_ text: String) -> some View {
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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.10)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                VStack(spacing: 24) {
                    // Stylish search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                        TextField("Search for places, news, or tips...", text: $query)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .onSubmit { performSearch() }
                        Button(action: performSearch) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(query.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                        }
                        .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    HStack(spacing: 20) {
                        Button("Local Food") {
                            if locationManager.authorizationStatus == .denied {
                                query = "what restaurant and food are in"
                            } else {
                                locationManager.onPlaceNameUpdate = { placeName in
                                    let searchQuery = "what restaurant and food are in \(placeName)"
                                    query = searchQuery
                                    performSearch()
                                }
                                locationManager.startUpdatingLocation()
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)

                        Button("Local TODO") {
                            if locationManager.authorizationStatus == .denied {
                                query = "what is there todo in"
                            } else {
                                locationManager.onPlaceNameUpdate = { placeName in
                                    let searchQuery = "what is there todo in \(placeName)"
                                    query = searchQuery
                                    performSearch()
                                }
                                locationManager.startUpdatingLocation()
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    }

                    Spacer(minLength: 0)

                    if let errorMessage = errorMessage {
                        Spacer()
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        Spacer()
                    } else if let searchOutput = searchOutput {
                        Spacer()
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Results")
                                    .font(.title2).bold()
                                    .foregroundColor(.blue)
                                
                                processContent(searchOutput)
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(12)
                                    .shadow(radius: 2)
                            }
                            .padding()
                        }
                        Spacer()
                    } else {
                        Spacer()
                        Text("No results yet. Try searching for something!")
                            .foregroundColor(.secondary)
                            .font(.headline)
                            .padding()
                             FormattedText(text: """
    # Header 1
    ## Header 2
    ### Header 3
    
    This is a paragraph with **bold** and *italic* text.
    
    [Duck Duck Go](https://duckduckgo.com)
    
    - List item 1
    - List item 2
    """)
                        Spacer()
                    }
                }
                .navigationTitle("Travel & News Finder")
                .font(.system(.body, design: .rounded))
                .padding(.top, 24)
                
                // Overlay for loading
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.8)
                        Text("Searching...")
                            .font(.title3).bold()
                            .foregroundColor(.blue)
                    }
                    .padding(32)
                    .background(BlurView(style: .systemMaterial))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                }
            }
        }
    }
    
    func performSearch() {
        UIApplication.shared.endEditing()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        results = []
        searchOutput = nil
        Task {
            do {
                let output = try await searchService.search(query: trimmed)
                await MainActor.run {
                    self.searchOutput = output
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    if let searchError = error as? SearchError {
                        switch searchError {
                        case .invalidURL:
                            self.errorMessage = "Invalid URL."
                        case .networkError(let err):
                            self.errorMessage = "Network error: \(err.localizedDescription)"
                        case .invalidResponse:
                            self.errorMessage = "Invalid response from server."
                        case .serverError(let msg):
                            self.errorMessage = "Server error: \(msg)"
                        }
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.isLoading = false
                }
            }
        }
    }
}

struct SearchResult: Identifiable, Decodable {
    let id: UUID
    let title: String
    let subtitle: String?
    let url: URL?
}


extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
