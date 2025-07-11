import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct PhotoStripOverlayView: View {
    @EnvironmentObject var iapManager: IAPManager
    @Binding var selectedPickerItems: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]
    @Binding var showResetConfirmation: Bool
    @Binding var isLandscape: Bool
    @Binding var photosPerPage: Int
    @Binding var projectTitle: String
    @Binding var showTitleOnPDF: Bool // Add this binding
    @Binding var imageToEdit: EditableAsset?
    let currentProject: PDFProject?
    let onOrientationChange: () -> Void
    let onPhotosPerPageChange: () -> Void
    let onPhotosAdded: () -> Void
    let onTitleVisibilityChange: () -> Void
    @State private var currentDraggingIndex: Int?
    @State private var selectedImageIndex: Int?
    @State private var localPickerItems: [PhotosPickerItem] = []
    @State private var showPhotoLimitAlert = false

    private let freeLimit = 3

    var body: some View {
        VStack(spacing: 12) {
            // Add the TextField for the project title here
            HStack {
                Text("Title:")
                    .font(.subheadline.weight(.medium))
                TextField("Project Title", text: $projectTitle)
                    .textFieldStyle(.roundedBorder)
                Button(action: {
                    showTitleOnPDF.toggle()
                    onTitleVisibilityChange()
                }) {
                    Image(systemName: showTitleOnPDF ? "eye" : "eye.slash")
                        .foregroundColor(showTitleOnPDF ? .blue : .gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            HStack(spacing: 0) {
                Button(action: {
                    if photosPerPage != 1 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            photosPerPage = 1
                        }
                        DispatchQueue.main.async {
                            onPhotosPerPageChange()
                        }
                    }
                }) {
                    Label("One Photo", systemImage: "photo")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(photosPerPage == 1 ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            photosPerPage == 1 ? Color.gray.opacity(0.8) : Color.gray.opacity(0.2)
                        )
                }
                .clipShape(RoundedCorners(radius: 8, corners: [.topLeft, .bottomLeft]))
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 34)
                
                Button(action: {
                    if photosPerPage != 2 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            photosPerPage = 2
                        }
                        DispatchQueue.main.async {
                            onPhotosPerPageChange()
                        }
                    }
                }) {
                    Label("Two Photos", systemImage: "rectangle.grid.1x2")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(photosPerPage == 2 ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            photosPerPage == 2 ? Color.gray.opacity(0.6) : Color.gray.opacity(0.2)
                        )
                }
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 34)
                
                Button(action: {
                    if photosPerPage != 4 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            photosPerPage = 4
                        }
                        DispatchQueue.main.async {
                            onPhotosPerPageChange()
                        }
                    }
                }) {
                    Label("2x2", systemImage: "rectangle.grid.2x2")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(photosPerPage == 4 ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            photosPerPage == 4 ? Color.gray.opacity(0.6) : Color.gray.opacity(0.2)
                        )
                }
                .clipShape(RoundedCorners(radius: 8, corners: [.topRight, .bottomRight]))
            }
            .padding(.horizontal)
            
            HStack(spacing: 0) {
                Button(action: {
                    if isLandscape != false {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isLandscape = false
                        }
                        DispatchQueue.main.async {
                            onOrientationChange()
                        }
                    }
                }) {
                    Label("Portrait", systemImage: "rectangle.portrait")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(!isLandscape ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            !isLandscape ? Color.gray.opacity(0.6) : Color.gray.opacity(0.2)
                        )
                }
                .clipShape(RoundedCorners(radius: 8, corners: [.topLeft, .bottomLeft]))
                
                Button(action: {
                    if isLandscape != true {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isLandscape = true
                        }
                        DispatchQueue.main.async {
                            onOrientationChange()
                        }
                    }
                }) {
                    Label("Landscape", systemImage: "rectangle")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(isLandscape ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            isLandscape ? Color.gray.opacity(0.6) : Color.gray.opacity(0.2)
                        )
                }
                .clipShape(RoundedCorners(radius: 8, corners: [.topRight, .bottomRight]))
            }
            .padding(.horizontal)
            HStack(spacing: 12) {
                ZStack {
                    PhotosPicker(
                        selection: $localPickerItems,
                        matching: .images
                    ) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 80, height: 80)
                            Image(systemName: "plus")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        }
                    }

                    if !iapManager.isPremium && selectedImages.count >= freeLimit {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.6))
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 80, height: 80)
                .alert("Photo Limit Reached", isPresented: $showPhotoLimitAlert) {
                    Button("OK") {}
                } message: {
                    Text("The free version allows up to \(freeLimit) photos. Please upgrade for unlimited photos.")
                }
                .onChange(of: localPickerItems) { newItems in
                    Task {
                        let availableSlots = iapManager.isPremium ? Int.max : freeLimit - selectedImages.count
                        guard availableSlots > 0 else {
                            await MainActor.run {
                                localPickerItems = []
                                showPhotoLimitAlert = true
                            }
                            return
                        }

                        let itemsToProcess = Array(newItems.prefix(availableSlots))

                        if !iapManager.isPremium && newItems.count > itemsToProcess.count {
                            await MainActor.run {
                                showPhotoLimitAlert = true
                            }
                        }

                        for item in itemsToProcess {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                
                                let resizedImage = uiImage.resize(to: CGSize(width: 500, height: 500)) ?? uiImage
                                
                                await MainActor.run {
                                    selectedImages.append(resizedImage)
                                }
                            }
                        }
                        await MainActor.run {
                            localPickerItems = []
                            onPhotosAdded()
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            Image(uiImage: selectedImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(selectedImageIndex == index ? .purple : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    if selectedImageIndex == index {
                                        selectedImageIndex = nil
                                    } else {
                                        selectedImageIndex = index
                                    }
                                }
                                .onDrag {
                                    self.currentDraggingIndex = index
                                    return NSItemProvider(object: String(index) as NSString)
                                }
                                .onDrop(of: [UTType.text], delegate: ImageDropDelegate(index: index, items: $selectedImages, currentDraggingIndex: $currentDraggingIndex))
                        }
                    }
                    .padding(.vertical)
                    .padding(.trailing)
                }
                .frame(height: 90)
            }
            .padding(.horizontal)

            if !selectedImages.isEmpty {
                VStack(spacing: 12) {
                    

                    if let selectedIndex = selectedImageIndex {
                        HStack {
                            Spacer()
                            Button(action: {
                                // Get the original image from the project if available
                                let originalImage: UIImage
                                if let project = currentProject, selectedIndex < project.originalImages.count {
                                    originalImage = project.originalImages[selectedIndex]
                                } else {
                                    originalImage = selectedImages[selectedIndex]
                                }
                                imageToEdit = EditableAsset(image: selectedImages[selectedIndex], originalImage: originalImage, index: selectedIndex)
                            }) {
                                Label("Edit", systemImage: "pencil.circle")
                                    .font(.subheadline.weight(.medium))
                            }
                            Spacer()
                            Divider().frame(height: 20)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    selectedImages.remove(at: selectedIndex)
                                    selectedImageIndex = nil
                                }
                            }) {
                                Label("Remove", systemImage: "trash.circle")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Button(action: {
                            showResetConfirmation = true
                        }) {
                            Label("Delete Project", systemImage: "trash")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .padding(.vertical)
        .padding(.bottom, 20)
        .background(BlurView(style: .systemUltraThinMaterial))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 10)
        .alert("Remove All Photos?", isPresented: $showResetConfirmation) {
            Button("Remove All", role: .destructive) {
                selectedImages.removeAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete the project and all photos.")
        }
    }
} 
