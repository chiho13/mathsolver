import SwiftUI
import UIKit
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

struct ContentView: View {
    @State private var query: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @StateObject private var searchService = SearchAPIService()
    @State private var searchOutput: String? = nil
    @StateObject private var languageSettings = LanguageSettingsViewModel()
    @FocusState private var isTextFieldFocused: Bool
    @State private var showSidebar: Bool = false
    @State private var showPremiumView: Bool = false
    @Environment(\.modelContext) private var modelContext
    @State private var searchHistory: SearchHistoryManager?
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showResetConfirmation = false
    @State private var pdfURL: URL?
    @State private var isLandscape = false
    @State private var showPhotoStrip = false
    @State private var photosPerPage = 1
    @State private var scrollToBottom = false

    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.10)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                
                VStack(spacing: 0) {
                    if let pdfURL = pdfURL {
                        PDFPreviewView(url: pdfURL, isLandscape: isLandscape, shouldScrollToBottom: $scrollToBottom)
                            .id("\(pdfURL.absoluteString)_\(isLandscape)_\(photosPerPage)_\(selectedImages.count)")
                            .padding(.top, 10)
                            .padding(.bottom, showPhotoStrip ? 290 : 40)
                            .padding(.horizontal, 10)
                            .animation(.easeInOut(duration: 0.3), value: showPhotoStrip)
                    } else if let errorMessage = errorMessage {
                        VStack {
                            Spacer()
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                                .shadow(radius: 4)
                            Spacer()
                        }
                    } else if isLoading {
                        VStack {
                            Spacer()
                            LoadingThreeBalls(color: .blue)
                            Text("Searching...")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                            Spacer()
                        }
                    } else if searchOutput != nil {
                        // This case is now less likely to be visible, might need rethinking if search is a primary feature
                        SearchResultsView(searchOutput: searchOutput!)
                    } else {
                        PhotoSelectorView(selectedPickerItems: $selectedPickerItems)
                    }
                }
                .animation(.easeInOut, value: pdfURL)
                
                // Sidebar overlay
                // if showSidebar, let searchHistory = searchHistory {
                //     SidebarView(
                //         showSidebar: $showSidebar,
                //         searchHistory: searchHistory,
                //         query: $query,
                //         searchOutput: $searchOutput
                //     )
                //     .zIndex(1)
                // }
            }
            .overlay(alignment: .bottomTrailing) {
                if !selectedImages.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPhotoStrip.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: showPhotoStrip ? "eye.slash" : "slider.horizontal.3")
                            Text(showPhotoStrip ? "Hide" : "Edit")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(showPhotoStrip ? Color.gray.opacity(0.8) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(radius: 4)
                    }
                    .padding()
                    .padding(.bottom, showPhotoStrip ? 270 : 20) // Move up when overlay is visible
                    .animation(.easeInOut(duration: 0.3), value: showPhotoStrip)
                }
            }
            .overlay(alignment: .bottom) {
                if !selectedImages.isEmpty && showPhotoStrip {
                    PhotoStripOverlayView(
                        selectedPickerItems: $selectedPickerItems,
                        selectedImages: $selectedImages,
                        showResetConfirmation: $showResetConfirmation,
                        isLandscape: $isLandscape,
                        photosPerPage: $photosPerPage,
                        onOrientationChange: generatePDF,
                        onPhotosPerPageChange: generatePDF,
                        onPhotosAdded: generatePDF
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .onAppear {
                if searchHistory == nil {
                    searchHistory = SearchHistoryManager(modelContext: modelContext)
                }
            }
            .onChange(of: selectedImages) { _ in
                if selectedImages.isEmpty {
                    pdfURL = nil
                    showPhotoStrip = false
                } else {
                    generatePDF()
                    showPhotoStrip = true
                }
            }
            .onChange(of: selectedPickerItems) { newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await MainActor.run {
                                self.selectedImages.append(uiImage)
                            }
                        }
                    }
                    await MainActor.run {
                        selectedPickerItems = []
                        // Force PDF regeneration after adding new photos
                        if !selectedImages.isEmpty {
                            generatePDF()
                        }
                    }
                }
            }
            .animation(.easeInOut, value: !selectedImages.isEmpty)
            .animation(.easeInOut(duration: 0.3), value: showSidebar)
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showPremiumView) {
                PremiumView(headline: "paywall-title")
            }
            .toolbar {
                // ToolbarItem(placement: .navigationBarLeading) {
                //     Button(action: {
                //         withAnimation(.easeInOut(duration: 0.1)) {
                //             showSidebar = true
                //         }
                //     }) {
                //         Image(systemName: "sidebar.left")
                //             .font(.system(size: 16, weight: .medium))
                //             .foregroundColor(.blue)
                //             .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                //             .contentShape(Rectangle())
                //             .padding(8)
                //             .background(
                //                 RoundedRectangle(cornerRadius: 8)
                //                     .fill(Color.white.opacity(0.8))
                //                     .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                //             )
                //     }
                //     .padding(.top, 8)
                //     .opacity(showSidebar ? 0 : 1)
                // }
                

                // Always show Upgrade button (in secondary position when PDF exists)
                ToolbarItem(placement: pdfURL != nil ? .navigationBarTrailing : .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            showPremiumView = true
                        }
                    }) {
                       
                            // Full button when no PDF
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
                    .padding(.leading, pdfURL != nil ? 8 : 0) // Add spacing when both buttons are present
                    .opacity(showPremiumView ? 0 : 1)
                }

                // PDF Control Buttons (when PDF is available)
                if let pdfURL = pdfURL {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 8) {
                            // Scroll to Bottom Button
                            // Button(action: {
                            //     scrollToBottom = true
                            // }) {
                            //     Image(systemName: "arrow.down.to.line")
                            //         .font(.system(size: 14, weight: .medium))
                            //         .foregroundColor(.white)
                            //         .padding(8)
                            //         .background(
                            //             LinearGradient(gradient: Gradient(colors: [.green, .green.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                            //         )
                            //         .cornerRadius(8)
                            // }
                            
                            // Share Button
                            ShareLink(item: pdfURL) {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Share")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(8)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.trailing, -8)
                    }
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
        searchOutput = nil
        Task {
            do {
                let output = try await searchService.search(query: trimmed, language: languageSettings.plainEnglish[languageSettings.sourceLanguage] ?? "English")
                await MainActor.run {
                    self.searchOutput = output
                    self.isLoading = false
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
    
    func generatePDF() {
        guard !selectedImages.isEmpty else { return }
        print("Generating PDF with \(selectedImages.count) images")
        let pdfData = NSMutableData()
        // A4 paper size in points (210mm x 297mm)
        var pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        if isLandscape {
            pageRect = CGRect(x: 0, y: 0, width: 842, height: 595)
        }
        let margin: CGFloat = 36.0 // 0.5 inch margin
        let imageableArea = pageRect.insetBy(dx: margin, dy: margin)

        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)
        
        if photosPerPage == 1 {
            // One photo per page
            for img in selectedImages {
                UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
                let aspectFitRect = AVMakeRect(aspectRatio: img.size, insideRect: imageableArea)
                img.draw(in: aspectFitRect)
            }
        } else if photosPerPage == 2 {
            // Two photos per page
            for i in stride(from: 0, to: selectedImages.count, by: 2) {
                UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
                
                let firstImage = selectedImages[i]
                let spacing: CGFloat = 20
                
                if i + 1 < selectedImages.count {
                    // Two images on this page
                    let secondImage = selectedImages[i + 1]
                    let availableHeight = imageableArea.height - spacing
                    let halfHeight = availableHeight / 2
                    
                    // Top image
                    let topRect = CGRect(x: imageableArea.minX, y: imageableArea.minY, 
                                       width: imageableArea.width, height: halfHeight)
                    let topAspectFitRect = AVMakeRect(aspectRatio: firstImage.size, insideRect: topRect)
                    firstImage.draw(in: topAspectFitRect)
                    
                    // Bottom image
                    let bottomRect = CGRect(x: imageableArea.minX, y: imageableArea.minY + halfHeight + spacing,
                                          width: imageableArea.width, height: halfHeight)
                    let bottomAspectFitRect = AVMakeRect(aspectRatio: secondImage.size, insideRect: bottomRect)
                    secondImage.draw(in: bottomAspectFitRect)
                } else {
                    // Only one image on this page (last page with odd number of images)
                    let aspectFitRect = AVMakeRect(aspectRatio: firstImage.size, insideRect: imageableArea)
                    firstImage.draw(in: aspectFitRect)
                }
            }
        } else if photosPerPage == 4 {
            // 2x2 grid - four photos per page
            for i in stride(from: 0, to: selectedImages.count, by: 4) {
                UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
                
                let spacing: CGFloat = 15
                let availableWidth = imageableArea.width - spacing
                let availableHeight = imageableArea.height - spacing
                let halfWidth = availableWidth / 2
                let halfHeight = availableHeight / 2
                
                // Top-left (index i)
                if i < selectedImages.count {
                    let topLeftRect = CGRect(x: imageableArea.minX, y: imageableArea.minY,
                                           width: halfWidth, height: halfHeight)
                    let topLeftAspectFitRect = AVMakeRect(aspectRatio: selectedImages[i].size, insideRect: topLeftRect)
                    selectedImages[i].draw(in: topLeftAspectFitRect)
                }
                
                // Top-right (index i+1)
                if i + 1 < selectedImages.count {
                    let topRightRect = CGRect(x: imageableArea.minX + halfWidth + spacing, y: imageableArea.minY,
                                            width: halfWidth, height: halfHeight)
                    let topRightAspectFitRect = AVMakeRect(aspectRatio: selectedImages[i+1].size, insideRect: topRightRect)
                    selectedImages[i+1].draw(in: topRightAspectFitRect)
                }
                
                // Bottom-left (index i+2)
                if i + 2 < selectedImages.count {
                    let bottomLeftRect = CGRect(x: imageableArea.minX, y: imageableArea.minY + halfHeight + spacing,
                                              width: halfWidth, height: halfHeight)
                    let bottomLeftAspectFitRect = AVMakeRect(aspectRatio: selectedImages[i+2].size, insideRect: bottomLeftRect)
                    selectedImages[i+2].draw(in: bottomLeftAspectFitRect)
                }
                
                // Bottom-right (index i+3)
                if i + 3 < selectedImages.count {
                    let bottomRightRect = CGRect(x: imageableArea.minX + halfWidth + spacing, y: imageableArea.minY + halfHeight + spacing,
                                               width: halfWidth, height: halfHeight)
                    let bottomRightAspectFitRect = AVMakeRect(aspectRatio: selectedImages[i+3].size, insideRect: bottomRightRect)
                    selectedImages[i+3].draw(in: bottomRightAspectFitRect)
                }
            }
        }
        
        UIGraphicsEndPDFContext()

        // Create filename with today's date and timestamp to ensure uniqueness
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestampString = dateFormatter.string(from: Date())
        let filename = "Photos_\(timestampString)_\(selectedImages.count).pdf"
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try pdfData.write(to: url, atomically: true)
            pdfURL = url
        } catch {
            print("Failed to write PDF data: \(error)")
        }
    }
}

