import SwiftUI
import PhotosUI

struct PhotoSelectorView: View {
    @Binding var selectedPickerItems: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]
    @Binding var currentProject: PDFProject?
    @State private var showPremiumAlert = false
    @State private var showProjectNameAlert = false
    @State private var projectName = ""
    @State private var pendingPickerItems: [PhotosPickerItem] = []
    @EnvironmentObject var iapManager: IAPManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    private let freeLimit = 3
    
    var body: some View {
        PhotosPicker(
            selection: $selectedPickerItems,
            maxSelectionCount: iapManager.isPremium ? nil : freeLimit,
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack {
                Spacer()
                
                VStack(spacing: 24) {
                    // MARK: - Icon
                    ZStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)

                        ZStack {
                            Circle().fill(Color.white)
                                .frame(width: 22, height: 22)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        .offset(x: 22, y: -22)
                    }
                    .frame(width: 72, height: 72)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // MARK: - Title and Subtitle
                    VStack(spacing: 8) {
                        Text("Add New Project")
                            .font(.title.bold())
                            .foregroundColor(.primary)
                        
                        Text("Tap to select photos and create a PDF")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // MARK: - Premium Status Indicator
                    if iapManager.didCheckPremium {
                        if !iapManager.isPremium {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "lock.fill")
                                    Text("Free limit: \(freeLimit) photos per project")
                                }
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                
                                Button(action: {
                                    NotificationCenter.default.post(name: NSNotification.Name("ShowPremiumView"), object: nil)
                                }) {
                                    Text("Upgrade for Unlimited Photos")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 24)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue, .purple]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(16)
                                        .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text("Premium: Unlimited photos")
                                    .fontWeight(.semibold)
                            }
                            .font(.callout)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(16)
                        }
                    } else {
                        // Placeholder for layout consistency before premium check
                        VStack {
                            ProgressView()
                            Text("Checking status...")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: colorScheme == .dark ? .white.opacity(0.05) : .black.opacity(0.08), radius: 12, x: 0, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer() // Pushes the card up slightly from the center
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .alert("Upgrade to Premium", isPresented: $showPremiumAlert) {
            Button("Upgrade") {
                // This would trigger the premium view
                NotificationCenter.default.post(name: NSNotification.Name("ShowPremiumView"), object: nil)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Upgrade to Premium to select unlimited photos and unlock all features!")
        }
        .alert("Create New Project", isPresented: $showProjectNameAlert) {
            TextField("Project name", text: $projectName)
            Button("Create") {
                let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    // Create PDFProject immediately
                    let newProject = PDFProject(title: trimmedName)
                    modelContext.insert(newProject)
                    
                    // Save the context
                    do {
                        try modelContext.save()
                        currentProject = newProject
                    } catch {
                        print("Failed to save project: \(error)")
                    }
                    
                    // Process pending photos directly to avoid duplication
                    Task {
                        for item in pendingPickerItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                await MainActor.run {
                                    selectedImages.append(uiImage)
                                }
                            }
                        }
                        await MainActor.run {
                            pendingPickerItems = []
                            projectName = ""
                        }
                    }
                }
            }
            .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) {
                // Clear pending items if user cancels
                pendingPickerItems = []
                projectName = ""
            }
        } message: {
            Text("Enter a name for your new PDF project.")
        }
        .onChange(of: selectedPickerItems) { newItems in
            // Don't process empty selections
            guard !newItems.isEmpty else { return }
            
            // Check if user is trying to select more than the free limit
            if !iapManager.isPremium && selectedImages.count + newItems.count > freeLimit {
                showPremiumAlert = true
                return
            }
            
            // Store the pending items and show project name dialog
            pendingPickerItems = newItems
            selectedPickerItems = [] // Clear the picker selection temporarily
            showProjectNameAlert = true
        }
    }
} 