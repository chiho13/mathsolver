import SwiftUI

struct SidebarView: View {
    @Binding var showSidebar: Bool
    @ObservedObject var searchHistory: SearchHistoryManager
    @Binding var query: String
    @Binding var searchOutput: String?
    @State private var showingClearConfirmation = false
    @State private var itemToDelete: SearchHistoryItem?
    @StateObject private var languageSettings = LanguageSettingsViewModel()
    @State private var showingLanguageSheet = false
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay with fade transition
            if showSidebar {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSidebar = false
                        }
                    }
                    .transition(.opacity)
            }
            
            // Sidebar content with slide transition
            if showSidebar {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("PDF Reporter")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSidebar = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.bottom, 10)
                        
                        Divider()
                        
                        // Search History Section
                        if !searchHistory.items.isEmpty {
                            Text("Search History")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(.top, 10)
                            
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 12) {
                                    ForEach(searchHistory.items.reversed()) { item in
                                        Button(action: {
                                            query = item.query
                                            searchOutput = item.result
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showSidebar = false
                                            }
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(item.query)
                                                        .font(.system(size: 15, weight: .medium))
                                                        .foregroundColor(.primary)
                                                        .lineLimit(1)
                                                    
                                                    Text(item.timestamp, style: .date)
                                                        .font(.caption2)
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                                
                                                Button(action: {
                                                    itemToDelete = item
                                                }) {
                                                    Image(systemName: "trash")
                                                        .font(.caption)
                                                        .foregroundColor(.red.opacity(0.8))
                                                }
                                                .padding(.leading, 8)
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: .infinity)
                            .confirmationDialog(
                                "Are you sure?",
                                isPresented: .init(
                                    get: { itemToDelete != nil },
                                    set: { if !$0 { itemToDelete = nil } }
                                ),
                                titleVisibility: .visible
                            ) {
                                Button("Delete", role: .destructive) {
                                    if let item = itemToDelete {
                                        withAnimation {
                                            searchHistory.deleteItem(item)
                                        }
                                    }
                                    itemToDelete = nil
                                }
                                Button("Cancel", role: .cancel) {
                                    itemToDelete = nil
                                }
                            } message: {
                                if let item = itemToDelete {
                                    Text("Are you sure you want to delete \"\(item.query)\"?")
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 10)
                        }
                        
                        // Clear All button
                        Button(action: {
                            showingClearConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All History")
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                        }
                        .confirmationDialog(
                            "Are you sure?",
                            isPresented: $showingClearConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Clear All", role: .destructive) {
                                withAnimation {
                                    searchHistory.clearAll()
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will delete all search history")
                        }
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        // Language Settings
                        Text("Language Settings")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.top, 10)
                        
                        Button(action: {
                            showingLanguageSheet = true
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                Text(languageSettings.availableLanguages[languageSettings.sourceLanguage] ?? "Select Language")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .foregroundColor(.primary)
                            .padding(.vertical, 8)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .frame(width: 300)
                    .background(Color(.systemBackground))
                    
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.move(edge: .leading))
            }
        }
        .sheet(isPresented: $showingLanguageSheet) {
            LanguageSelectionSheet(
                selectedLanguage: $languageSettings.sourceLanguage,
                languages: languageSettings.availableLanguages.map { Language(id: $0.key, displayName: $0.value) },
                placeholder: "Search"
            )
        }
    }
}
