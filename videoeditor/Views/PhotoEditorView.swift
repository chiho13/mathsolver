import SwiftUI
import Mantis

struct PhotoEditorView: View {
    let asset: EditableAsset
    let onDone: (EditableAsset?) -> Void

    @State private var image: UIImage
    @State private var currentAsset: EditableAsset

    init(asset: EditableAsset, onDone: @escaping (EditableAsset?) -> Void) {
        self.asset = asset
        self.onDone = onDone
        _image = State(initialValue: asset.image)
        _currentAsset = State(initialValue: asset)
    }

    var body: some View {
        ZStack {
            MantisCropViewRepresentable(
                image: image,
                onCrop: { croppedImage in
                    let resultAsset = currentAsset.withModifiedImage(croppedImage)
                    onDone(resultAsset)
                },
                onCancel: {
                    onDone(nil)
                }
            )
            .ignoresSafeArea(.all)
            
            // Revert button overlay - only show if image has been modified
            if currentAsset.isModified {
                VStack {
                    HStack {
                        Button(action: {
                            // Update the current image to the original and refresh the cropper
                            image = currentAsset.originalImage
                            currentAsset = currentAsset.reverted()
                        }) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Revert to Original")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(20)
                        }
                        .padding(.leading, 20)
                        .padding(.top, 30) // Position below status bar
                        .padding(.bottom, 20)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}

struct MantisCropViewRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = CropViewController

    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> CropViewController {
        let cropViewController = Mantis.cropViewController(image: image)
        cropViewController.delegate = context.coordinator
        cropViewController.modalPresentationStyle = .fullScreen
        return cropViewController
    }

    func updateUIViewController(_ uiViewController: CropViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CropViewControllerDelegate {
        var parent: MantisCropViewRepresentable

        init(_ parent: MantisCropViewRepresentable) {
            self.parent = parent
        }

        func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
            parent.onCrop(cropped)
        }

        func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
            parent.onCancel()
        }
    }
}

