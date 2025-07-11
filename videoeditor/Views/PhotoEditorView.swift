import SwiftUI
import Mantis

struct PhotoEditorView: View {
    let asset: EditableAsset
    let onDone: (EditableAsset?) -> Void

    @State private var image: UIImage

    init(asset: EditableAsset, onDone: @escaping (EditableAsset?) -> Void) {
        self.asset = asset
        self.onDone = onDone
        _image = State(initialValue: asset.image)
    }

    var body: some View {
        MantisCropViewRepresentable(
            image: image,
            onCrop: { croppedImage in
                let resultAsset = EditableAsset(image: croppedImage, index: asset.index)
                onDone(resultAsset)
            },
            onCancel: {
                onDone(nil)
            }
        )
        .ignoresSafeArea(.all)
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

