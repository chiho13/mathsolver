////
////  Language.swift
////  videoeditor
////
////  Created by Anthony Ho on 18/06/2025.
////
//
//
////
////  LanguagePickerView.swift
////  all ears
////
////  Created by Anthony Ho on 18/12/2024.
////
//
//import Foundation
//
//import SwiftUI
//
//struct Language {
//    let id: String
//    let displayName: String
//}
//
//import SwiftUI
//
//struct LanguagePickerView: View {
//    @Binding var selectedLanguage: String
//    let languages: [Language]
//    let placeholder: String
//    var textColor: Color = .white
//    var borderColor: Color = .white
//    
//    var body: some View {
//        CustomPickerButton(
//            selectedLanguage: $selectedLanguage,
//            languages: languages,
//            placeholder: placeholder,
//            textColor: textColor,
//            borderColor: borderColor
//        )
//    }
//}
//
//
//struct CustomPickerButton: View {
//    @Binding var selectedLanguage: String
//    let languages: [Language]
//    var placeholder: String = "Select Language"
//    var textColor: Color = .white
//    var borderColor: Color = .white
//    @Environment(\.colorScheme) var colorScheme
//    @State private var isSheetPresented = false
//
//    var body: some View {
//        Button(action: {
//            isSheetPresented.toggle()
//        }) {
//            Text(displayName(for: selectedLanguage) ?? (selectedLanguage.isEmpty ? placeholder : selectedLanguage))
//                .font(.system(size: 18, weight: .semibold))
//                .foregroundColor(colorScheme == .dark ? textColor.lighten().opacity(0.9) : textColor)
//                .frame(maxWidth: .infinity, minHeight: 40)
//                .padding(5)
//                .background(
//                    // Glass effect background
//                    RoundedRectangle(cornerRadius: 15, style: .continuous)
//                        .fill(Color.clear)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 15, style: .continuous)
//                                .fill(
//                                    LinearGradient(
//                                        colors: [
//                                            Color.white.opacity(0.01),
//                                            Color.white.opacity(0.02)
//                                        ],
//                                        startPoint: .topLeading,
//                                        endPoint: .bottomTrailing
//                                    )
//                                )
//                        )
//                )
//                .overlay(
//                    // Glass border effect
//                    RoundedRectangle(cornerRadius: 15, style: .continuous)
//                        .stroke(
//                            LinearGradient(
//                                colors: [
//                                    Color.white.opacity(0.8),
//                                    Color.fromHex("#A23B67").opacity(0.5),
//                                    Color.white.opacity(0.8)
//                                ],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            ),
//                            lineWidth: 1
//                        )
//                )
//                .overlay(
//                    // Inner highlight border
//                    RoundedRectangle(cornerRadius: 15, style: .continuous)
//                        .stroke(Color.white.opacity(0.8), lineWidth: 0.5)
//                        .padding(0.5)
//                )
//        }
//        .buttonStyle(PickerPressableButtonStyle(textColor: textColor))
//        .sheet(isPresented: $isSheetPresented) {
//            LanguageSelectionSheet(selectedLanguage: $selectedLanguage, languages: languages, placeholder: placeholder)
//        }
//    }
//
//    private func displayName(for id: String) -> String? {
//        languages.first(where: { $0.id == id })?.displayName
//    }
//}
//
////struct PickerPressableButtonStyle: ButtonStyle {
////    var textColor: Color = .white
////    func makeBody(configuration: Configuration) -> some View {
////        configuration.label
////            .background(
////                configuration.isPressed ? .black.opacity(0.1) : textColor.opacity(0.1)
////            )
////            .cornerRadius(15)
////            .opacity(configuration.isPressed ? 0.9 : 1.0)
////            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
////            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
////    }
////}
//
//struct LanguageSelectionSheet: View {
//    @Binding var selectedLanguage: String
//    let languages: [Language]
//    var placeholder: String
//    @Environment(\.dismiss) var dismiss
//    @Environment(\.colorScheme) var colorScheme
//    
//    @State private var searchText = ""
//   
//    @AppStorage("recentLanguages") private var recentLanguagesData: Data = {
//        (try? JSONEncoder().encode([String]())) ?? Data()
//    }()
//    
//    @State private var frameHeight: CGFloat = 30 // Initial height
//
//    private var recentLanguages: [String] {
//        get {
//            do {
//                let decoded = try JSONDecoder().decode([String].self, from: recentLanguagesData)
//                return decoded
//            } catch {
//                print("Failed to decode recent languages: \(error.localizedDescription)")
//                return []
//            }
//        }
//        set {
//            do {
//                let encoded = try JSONEncoder().encode(newValue)
//                recentLanguagesData = encoded
//            } catch {
//                print("Failed to encode recent languages: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    var body: some View {
//        NavigationView {
//            List {
//                // Show "Recently Used" only when there is no active search text
//                if !recentLanguages.isEmpty && searchText.isEmpty {
//                    Section(header: Text("Recently Used")) {
//                        ForEach(recentLanguages.prefix(6), id: \.self) { langId in
//                            if let lang = languages.first(where: { $0.id == langId }) {
//                                languageButton(for: lang)
//                            }
//                        }
//                    }
//                }
//                
//                // All Languages Section (filtered)
//                Section(header: Text("All Languages")) {
//                    ForEach(filteredLanguages, id: \.id) { lang in
//                        languageButton(for: lang)
//                    }
//                }
//            }
//            .searchable(text: $searchText, prompt: "Search Languages")
//            .environment(\.defaultMinListHeaderHeight, 40)
//            .navigationTitle("Select Language")
//            .navigationBarTitleDisplayMode(.inline)
//            .background(colorScheme == .dark ? Color.fromHex("#151013") : Color(.systemBackground))
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        dismiss()
//                    }) {
//                        Circle()
//                            .fill(Color.gray.opacity(0.7))
//                            .frame(width: 30, height: 30)
//                            .overlay(
//                                Image(systemName: "xmark")
//                                    .font(.system(size: 12, weight: .bold))
//                                    .foregroundColor(.white.opacity(0.8))
//                                    .padding(4)
//                            )
//                    }
//                    .offset(x: 4)
//                }
//            }
//        }
//    }
//    
//    private var filteredLanguages: [Language] {
//        let filtered = searchText.isEmpty ?
//            languages :
//            languages.filter { $0.displayName.lowercased().contains(searchText.lowercased()) }
//        return filtered.sorted {
//            $0.displayName.unicodeScalars.filter { !$0.properties.isEmoji }
//                .map(String.init)
//                .joined().lowercased() <
//            $1.displayName.unicodeScalars.filter { !$0.properties.isEmoji }
//                .map(String.init)
//                .joined().lowercased()
//        }
//    }
//    
//    private func languageButton(for lang: Language) -> some View {
//        Button(action: {
//            selectedLanguage = lang.id
//            updateRecentLanguages(with: lang.id)
//            dismiss()
//        }) {
//            HStack {
//                Text(lang.displayName)
//                    .font(.system(size: 18))
//                    .foregroundColor(lang.id == selectedLanguage ? .white : .primary)
//                Spacer()
//                if lang.id == selectedLanguage {
//                    Image(systemName: "checkmark")
//                        .foregroundColor(.white)
//                }
//            }
//            .padding(.vertical, 12)
//            .padding(.horizontal, 16)
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .background(
//                     Rectangle()
//                         .fill(lang.id == selectedLanguage ? .accentColor :
//                               (colorScheme == .dark ? Color.fromHex("#2e2636") : Color.clear))
//                 )
//            .contentShape(Rectangle())
//        }
//        .listRowInsets(EdgeInsets())
//        .listRowBackground(colorScheme == .dark ? Color.fromHex("#2e2636") : Color(.systemBackground))
//    }
//    
//    private func updateRecentLanguages(with id: String) {
//        var updatedRecentLanguages = recentLanguages
//        
//        if !updatedRecentLanguages.contains(id) {
//            // Add the new language at the end
//            updatedRecentLanguages.append(id)
//            // Keep only the 6 most recent languages
//            if updatedRecentLanguages.count > 6 {
//                updatedRecentLanguages = Array(updatedRecentLanguages.suffix(6))
//            }
//            do {
//                let encoded = try JSONEncoder().encode(updatedRecentLanguages)
//                recentLanguagesData = encoded
//            } catch {
//                print("Failed to encode recent languages: \(error.localizedDescription)")
//            }
//        } else {
//            print("Language with id \(id) already exists in recentLanguages.")
//        }
//    }
//}
