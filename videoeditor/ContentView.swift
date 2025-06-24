import SwiftUI
import UIKit
import SwiftData

struct ContentView: View {
    @State private var query: String = ""
    @State private var results: [SearchResult] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @StateObject private var searchService = SearchAPIService()
    @State private var searchOutput: String? = nil
    @StateObject private var locationManager = LocationManager()
    @StateObject private var languageSettings = LanguageSettingsViewModel()
    @FocusState private var isTextFieldFocused: Bool
    @State private var showSidebar: Bool = false
    @State private var showPremiumView: Bool = false
    @Environment(\.modelContext) private var modelContext
    @State private var searchHistory: SearchHistoryManager?
    
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
                // Main content
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.10)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                VStack(spacing: searchOutput == nil && errorMessage == nil && !isLoading ? 0 : 24) {
                    
                    if searchOutput != nil || errorMessage != nil || isLoading {
                        // When results are shown or loading, add top spacing
                        Spacer().frame(height: 2)
                    } else {
                        // When no results and not loading, center vertically
                        Spacer()
                    }
                    
                    // Search interface container
                    VStack(spacing: 24) {
                        // Stylish search bar
                        ZStack {
                            TextField("Search for places, news, or tips...", text: $query)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .padding(.leading, 45)
                                .padding(.trailing, 55)
                                .padding(.vertical, 19)
                                .background(
                                    ZStack {
                                        Color.white
                                        Color(.systemGray6).opacity(isTextFieldFocused ? 0.3 : 1.0)
                                    }
                                )
                                .cornerRadius(16)
                                .overlay(
                                    // Gradient border overlay when focused
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(
                                            isTextFieldFocused ? 
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue, .purple.opacity(0.8), .blue]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ) : 
                                            LinearGradient(
                                                gradient: Gradient(colors: [.clear]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                        .opacity(isTextFieldFocused ? 1 : 0)
                                )
                                .focused($isTextFieldFocused)
                                .shadow(
                                    color: isTextFieldFocused 
                                    ? Color.blue.opacity(0.2) 
                                    : Color.black.opacity(0.05), 
                                    radius: isTextFieldFocused ? 8 : 4, 
                                    x: 0, 
                                    y: isTextFieldFocused ? 4 : 2
                                )
                                .onSubmit { performSearch() }
                            
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(isTextFieldFocused ? .blue : .blue.opacity(0.7))
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.leading, 15)
                                
                                Spacer()
                                
                                Button(action: performSearch) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(
                                            query.trimmingCharacters(in: .whitespaces).isEmpty 
                                            ? .gray.opacity(0.4) 
                                            : (isTextFieldFocused ? .blue : .blue.opacity(0.8))
                                        )
                                }
                                .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
                                .padding(.trailing, 15)
                            }
                            
                        }
                        .padding(.horizontal)
                        .animation(.easeOut(duration: 0.12), value: isTextFieldFocused)

                        // HStack(spacing: 20) {
                        //     Button("Local Food") {
                        //         if locationManager.authorizationStatus == .denied {
                        //             query = "what restaurant and food are in"
                        //         } else {
                        //             locationManager.onPlaceNameUpdate = { placeName in
                        //                 let searchQuery = "what restaurant and food are in \(placeName)"
                        //                 query = searchQuery
                        //                 performSearch()
                        //             }
                        //             locationManager.startUpdatingLocation()
                        //         }
                        //     }
                        //     .font(.headline)
                        //     .foregroundColor(.white)
                        //     .padding()
                        //     .background(
                        //         LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                        //     )
                        //     .cornerRadius(10)
                        //     .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)

                        //     Button("Local TODO") {
                        //         if locationManager.authorizationStatus == .denied {
                        //             query = "what is there todo in"
                        //         } else {
                        //             locationManager.onPlaceNameUpdate = { placeName in
                        //                 let searchQuery = "what is there todo in \(placeName)"
                        //                 query = searchQuery
                        //                 performSearch()
                        //             }
                        //             locationManager.startUpdatingLocation()
                        //         }
                        //     }
                        //     .font(.headline)
                        //     .foregroundColor(.white)
                        //     .padding()
                        //     .background(
                        //         LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                        //     )
                        //     .cornerRadius(10)
                        //     .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        // }
                    }
                    
                    // Loading indicator
                    if isLoading {
                        HStack {
                          LoadingThreeBalls(color: .blue)
                            Text("Searching...")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    if searchOutput == nil && errorMessage == nil && !isLoading {
                        // When no results and not loading, center vertically with spacer below
                        Spacer()
                    }

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
                        VStack(alignment: .leading, spacing: 0) {
                            // Results header
                            // HStack {
                            //     Text("Results")
                            //         .font(.title2).bold()
                            //         .foregroundColor(.blue)
                            //     Spacer()
                            // }
                            // .padding(.horizontal, 20)
                            // .padding(.top, 16)
                            // .padding(.bottom, 12)
                            // .background(Color.white.opacity(0.95))
                            
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
                }
                .font(.system(.body, design: .rounded))
                .padding(.top, 24)
                .offset(y: searchOutput == nil && errorMessage == nil && !isLoading ? -40 : 0)
                .animation(.easeInOut(duration: 0.3), value: isLoading)
                .animation(.easeInOut(duration: 0.3), value: searchOutput != nil)
                .animation(.easeInOut(duration: 0.3), value: errorMessage != nil)
                
                // Sidebar overlay
                if showSidebar, let searchHistory = searchHistory {
                    SidebarView(
                        showSidebar: $showSidebar,
                        searchHistory: searchHistory,
                        query: $query,
                        searchOutput: $searchOutput
                    )
                        .zIndex(1)
                }
            }
            .onAppear {
                if searchHistory == nil {
                    searchHistory = SearchHistoryManager(modelContext: modelContext)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showSidebar)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPremiumView) {
                PremiumView(headline: "paywall-title")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            showSidebar = true
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                            .contentShape(Rectangle())
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.8))
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                    .padding(.top, 8)
                    .opacity(showSidebar ? 0 : 1)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            showPremiumView = true
                        }
                    }) {
                        Text("Upgrade")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)
                    .opacity(showPremiumView ? 0 : 1)
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
                let output = try await searchService.search(query: trimmed, language: languageSettings.plainEnglish[languageSettings.sourceLanguage] ?? "English")
                await MainActor.run {
                    self.searchOutput = output
                    self.isLoading = false
                    // Add to search history
                    self.searchHistory?.addItem(query: trimmed, result: output)
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
