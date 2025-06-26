import SwiftUI
import QuickLook

class ObservableQLPreviewController: QLPreviewController {
    var onIndexChanged: ((Int) -> Void)?

    override var currentPreviewItemIndex: Int {
        didSet {
            if oldValue != currentPreviewItemIndex {
                onIndexChanged?(currentPreviewItemIndex)
            }
        }
    }
}

struct QuickLookView: UIViewControllerRepresentable {
    let urls: [URL]
    @Binding var selectedIndex: Int

    func makeUIViewController(context: Context) -> ObservableQLPreviewController {
        let controller = ObservableQLPreviewController()
        controller.dataSource = context.coordinator
        controller.currentPreviewItemIndex = selectedIndex
        
        controller.onIndexChanged = { newIndex in
            context.coordinator.parent.selectedIndex = newIndex
        }
        
        return controller
    }

    func updateUIViewController(_ uiViewController: ObservableQLPreviewController, context: Context) {
        if uiViewController.currentPreviewItemIndex != selectedIndex {
            uiViewController.currentPreviewItemIndex = selectedIndex
        }
        uiViewController.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        var parent: QuickLookView

        init(parent: QuickLookView) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return parent.urls.count
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.urls[index] as QLPreviewItem
        }
    }
} 