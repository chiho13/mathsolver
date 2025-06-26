import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct PhotoStripOverlayView: View {
    @Binding var selectedPickerItems: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]
    @Binding var showResetConfirmation: Bool
    @Binding var isLandscape: Bool
    let onOrientationChange: () -> Void
    @State private var currentDraggingIndex: Int?
    @State private var selectedImageIndex: Int?

    var body: some View {
        VStack(spacing: 12) {
            Picker("Orientation", selection: $isLandscape) {
                        Label("Portrait", systemImage: "rectangle.portrait").tag(false)
                        Label("Landscape", systemImage: "rectangle.landscape").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isLandscape) { _ in
                        DispatchQueue.main.async {
                            onOrientationChange()
                        }
                    }.padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPickerItems, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 80, height: 80)
                            Image(systemName: "plus")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        }
                    }

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
                .padding()
            }
            .frame(height: 90)

            if !selectedImages.isEmpty {
                VStack(spacing: 12) {
                    

                    if let selectedIndex = selectedImageIndex {
                        HStack {
                            Spacer()
                            Button(action: {
                                // TODO: Implement edit action
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
                            Label("Remove All", systemImage: "trash")
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
            Text("This action cannot be undone.")
        }
    }
} 