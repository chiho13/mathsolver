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

    var body: some View {
        VStack(spacing: 12) {
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
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: selectedImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .cornerRadius(10)
                                .onDrag {
                                    self.currentDraggingIndex = index
                                    return NSItemProvider(object: String(index) as NSString)
                                }

                            Button(action: {
                                selectedImages.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.callout)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6).clipShape(Circle()))
                            }
                            .offset(x: 5, y: -5)
                        }
                        .onDrop(of: [UTType.text], delegate: ImageDropDelegate(index: index, items: $selectedImages, currentDraggingIndex: $currentDraggingIndex))
                    }
                }
                .padding()
            }
            .frame(height: 90)

            if !selectedImages.isEmpty {
                VStack(spacing: 12) {
                    Picker("Orientation", selection: $isLandscape) {
                        Label("Portrait", systemImage: "rectangle.portrait").tag(false)
                        Label("Landscape", systemImage: "rectangle.landscape").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isLandscape) { _ in
                        onOrientationChange()
                    }

                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        Label("Remove All", systemImage: "trash")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.red)
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