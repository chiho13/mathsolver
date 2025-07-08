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
    @State private var currentProject: PDFProject?
    @State private var showResetConfirmation = false
    @State private var pdfURL: URL?
    @State private var isLandscape = false
    @State private var showPhotoStrip = false
    @State private var photosPerPage = 1
    @State private var scrollToBottom = false
    @State private var addTextMode = false
    @EnvironmentObject private var iap: IAPManager

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
                    if let pdfURL = pdfURL, currentProject != nil {
                        PDFAnnotationView(url: pdfURL, addTextMode: $addTextMode) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPhotoStrip = false
                            }
                        }
                        .id("\(pdfURL.absoluteString)_\(isLandscape)_\(photosPerPage)_\(selectedImages.count)")
                        .padding(.top, 10)
                        .padding(.bottom, showPhotoStrip ? 340 : 40)
                        .padding(.horizontal, 10)
                        .animation(.easeInOut(duration: 0.3), value: showPhotoStrip)
                        .ignoresSafeArea(.keyboard)
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
                        HomeView(selectedPickerItems: $selectedPickerItems, selectedImages: $selectedImages, currentProject: $currentProject)
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
                            Image(systemName: showPhotoStrip ? "chevron.down" : "slider.horizontal.3")
                            Text(showPhotoStrip ? "Done" : "Edit")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(showPhotoStrip ? Color.gray.opacity(0.8) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(radius: 4)
                    }
                    .padding()
                    .padding(.bottom, showPhotoStrip ? 320 : 20) // Move up when overlay is visible
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
                        projectTitle: projectTitleBinding, // Pass the binding here
                        showTitleOnPDF: showTitleBinding, // Pass the new binding
                        onOrientationChange: {
                            updateProjectConfiguration()
                            generatePDF()
                        },
                        onPhotosPerPageChange: {
                            updateProjectConfiguration()
                            generatePDF()
                        },
                        onPhotosAdded: generatePDF,
                        onTitleVisibilityChange: {
                            updateProjectConfiguration()
                            generatePDF()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            // Bottom-leading annotation toggle (opposite the Edit/Hide button)
            // .overlay(alignment: .bottomLeading) {
            //     if pdfURL != nil {
            //         Button(action: {
            //             addTextMode.toggle()
            //         }) {
            //             HStack {
            //                 Image(systemName: addTextMode ? "pencil.slash" : "pencil")
            //                 Text(addTextMode ? "Done" : "Annotate")
            //             }
            //             .padding(.horizontal, 12)
            //             .padding(.vertical, 8)
            //             .background(addTextMode ? Color.orange.opacity(0.8) : Color.orange)
            //             .foregroundColor(.white)
            //             .cornerRadius(20)
            //             .shadow(radius: 4)
            //         }
            //         .padding()
            //         .padding(.bottom, showPhotoStrip ? 270 : 20)
            //         .animation(.easeInOut(duration: 0.3), value: showPhotoStrip)
            //     }
            // }
            .ignoresSafeArea(.container, edges: .bottom)
            .onAppear {
                if searchHistory == nil {
                    searchHistory = SearchHistoryManager(modelContext: modelContext)
                }
                
                // Listen for premium upgrade notifications
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowPremiumView"), object: nil, queue: .main) { _ in
                    showPremiumView = true
                }
            }
            .onChange(of: selectedImages) { _ in
                if selectedImages.isEmpty {
                    // Auto-delete empty project and return to home
                    if let project = currentProject {
                        modelContext.delete(project)
                        do {
                            try modelContext.save()
                            print("Empty project '\(project.title)' deleted automatically")
                        } catch {
                            print("Failed to delete empty project: \(error)")
                        }
                    }
                    
                    // Clear editor state and return to home
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentProject = nil
                        pdfURL = nil
                        showPhotoStrip = false
                        addTextMode = false
                    }
                } else {
                    // Update project with new images
                    if let project = currentProject {
                        project.updateImages(selectedImages)
                        project.updateConfiguration(isLandscape: isLandscape, photosPerPage: photosPerPage)
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to save project updates: \(error)")
                        }
                    }
                    generatePDF()
                    showPhotoStrip = true
                }
            }
            .onChange(of: selectedPickerItems) { newItems in
                // Only process photos if we already have a current project
                // (Photos from new project creation are handled in PhotoSelectorView)
                guard currentProject != nil else { return }
                
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
                // Back to Home button (when editing a project)
                if currentProject != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                // Auto-save current state before going back
                                if let project = currentProject {
                                    project.updateImages(selectedImages)
                                    project.updateConfiguration(isLandscape: isLandscape, photosPerPage: photosPerPage)
                                    do {
                                        try modelContext.save()
                                        print("Project '\(project.title)' saved automatically")
                                    } catch {
                                        print("Failed to auto-save project: \(error)")
                                    }
                                }
                                
                                // Clear editor state and return to home
                                currentProject = nil
                                selectedImages = []
                                pdfURL = nil
                                showPhotoStrip = false
                                addTextMode = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Projects")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
                    }
                }
                
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
                

                // Upgrade button (hidden when user is already premium)
                if iap.didCheckPremium && !iap.isPremium {
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
                        .padding(.bottom, 8)
                        .padding(.leading, pdfURL != nil ? 8 : 0)
                        .opacity(showPremiumView ? 0 : 1)
                    }
                }

                // PDF Control Buttons (when PDF is available)
                if let pdfURL = pdfURL {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 8) {
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
                         .padding(.bottom, 8)
                        .padding(.trailing, -8)
                    }
                }
                
            }
        }
    }

    private var projectTitleBinding: Binding<String> {
        Binding<String>(
            get: { self.currentProject?.title ?? "Untitled" },
            set: { self.currentProject?.title = $0 }
        )
    }

    private var showTitleBinding: Binding<Bool> {
        Binding<Bool>(
            get: { self.currentProject?.showTitle ?? true },
            set: { self.currentProject?.showTitle = $0 }
        )
    }

    private func updateProjectConfiguration() {
        guard let project = currentProject else { return }
        project.updateConfiguration(title: project.title, isLandscape: isLandscape, photosPerPage: photosPerPage, showTitle: project.showTitle)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save configuration: \(error)")
        }
    }

    private func generatePDF() {
        guard let project = currentProject else {
            errorMessage = "No active project to generate PDF for."
            return
        }
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
        
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        if photosPerPage == 1 {
            // One photo per page
            for (index, img) in selectedImages.enumerated() {
                UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
                var currentPageImageableArea = imageableArea
                
                // If it's the first page and title is enabled, draw title and adjust area
                if index == 0 && project.showTitle {
                    let title = project.title
                    let titleSize = title.size(withAttributes: titleAttributes)
                    let titleRect = CGRect(x: (pageRect.width - titleSize.width) / 2.0,
                                           y: imageableArea.minY,
                                           width: titleSize.width,
                                           height: titleSize.height)
                    title.draw(in: titleRect, withAttributes: titleAttributes)
                    
                    // Adjust imageable area for the image below the title
                    currentPageImageableArea.origin.y += titleSize.height + 20 // 20 points padding
                    currentPageImageableArea.size.height -= titleSize.height + 20
                }
                
                let aspectFitRect = AVMakeRect(aspectRatio: img.size, insideRect: currentPageImageableArea)
                img.draw(in: aspectFitRect)
            }
        } else if photosPerPage == 2 {
            // Two photos per page
            for i in stride(from: 0, to: selectedImages.count, by: 2) {
                UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
                var currentPageImageableArea = imageableArea

                // If it's the first page and title is enabled, draw title and adjust area
                if i == 0 && project.showTitle {
                    let title = project.title
                    let titleSize = title.size(withAttributes: titleAttributes)
                    let titleRect = CGRect(x: (pageRect.width - titleSize.width) / 2.0,
                                           y: imageableArea.minY,
                                           width: titleSize.width,
                                           height: titleSize.height)
                    title.draw(in: titleRect, withAttributes: titleAttributes)
                    
                    currentPageImageableArea.origin.y += titleSize.height + 20
                    currentPageImageableArea.size.height -= titleSize.height + 20
                }
                
                let firstImage = selectedImages[i]
                let spacing: CGFloat = 20
                
                if i + 1 < selectedImages.count {
                    let secondImage = selectedImages[i + 1]
                    let availableHeight = currentPageImageableArea.height - spacing
                    let halfHeight = availableHeight / 2
                    
                    let topRect = CGRect(x: currentPageImageableArea.minX, y: currentPageImageableArea.minY,
                                       width: currentPageImageableArea.width, height: halfHeight)
                    let topAspectFitRect = AVMakeRect(aspectRatio: firstImage.size, insideRect: topRect)
                    firstImage.draw(in: topAspectFitRect)
                    
                    let bottomRect = CGRect(x: currentPageImageableArea.minX, y: currentPageImageableArea.minY + halfHeight + spacing,
                                          width: currentPageImageableArea.width, height: halfHeight)
                    let bottomAspectFitRect = AVMakeRect(aspectRatio: secondImage.size, insideRect: bottomRect)
                    secondImage.draw(in: bottomAspectFitRect)
                } else {
                    let aspectFitRect = AVMakeRect(aspectRatio: firstImage.size, insideRect: currentPageImageableArea)
                    firstImage.draw(in: aspectFitRect)
                }
            }
        } else if photosPerPage == 4 {
            // 2x2 grid - four photos per page
            for i in stride(from: 0, to: selectedImages.count, by: 4) {
                UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
                var currentPageImageableArea = imageableArea

                // If it's the first page and title is enabled, draw title and adjust area
                if i == 0 && project.showTitle {
                    let title = project.title
                    let titleSize = title.size(withAttributes: titleAttributes)
                    let titleRect = CGRect(x: (pageRect.width - titleSize.width) / 2.0,
                                           y: imageableArea.minY,
                                           width: titleSize.width,
                                           height: titleSize.height)
                    title.draw(in: titleRect, withAttributes: titleAttributes)
                    
                    currentPageImageableArea.origin.y += titleSize.height + 20
                    currentPageImageableArea.size.height -= titleSize.height + 20
                }
                
                let spacing: CGFloat = 15
                let availableWidth = currentPageImageableArea.width - spacing
                let availableHeight = currentPageImageableArea.height - spacing
                let halfWidth = availableWidth / 2
                let halfHeight = availableHeight / 2
                
                if i < selectedImages.count {
                    let topLeftRect = CGRect(x: currentPageImageableArea.minX, y: currentPageImageableArea.minY,
                                           width: halfWidth, height: halfHeight)
                    let topLeftAspectFitRect = AVMakeRect(aspectRatio: selectedImages[i].size, insideRect: topLeftRect)
                    selectedImages[i].draw(in: topLeftAspectFitRect)
                }
                
                if i + 1 < selectedImages.count {
                    let topRightRect = CGRect(x: currentPageImageableArea.minX + halfWidth + spacing, y: currentPageImageableArea.minY,
                                            width: halfWidth, height: halfHeight)
                    let topRightAspectFitRect = AVMakeRect(aspectRatio: selectedImages[i+1].size, insideRect: topRightRect)
                    selectedImages[i+1].draw(in: topRightAspectFitRect)
                }
                
                if i + 2 < selectedImages.count {
                    let bottomLeftRect = CGRect(x: currentPageImageableArea.minX, y: currentPageImageableArea.minY + halfHeight + spacing,
                                              width: halfWidth, height: halfHeight)
                    let bottomLeftAspectFitRect = AVMakeRect(aspectRatio: selectedImages[i+2].size, insideRect: bottomLeftRect)
                    selectedImages[i+2].draw(in: bottomLeftAspectFitRect)
                }
                
                if i + 3 < selectedImages.count {
                    let bottomRightRect = CGRect(x: currentPageImageableArea.minX + halfWidth + spacing, y: currentPageImageableArea.minY + halfHeight + spacing,
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

