import SwiftUI
import QuickLook

struct PDFPreviewView: UIViewControllerRepresentable {
    let url: URL
    let isLandscape: Bool // Add isLandscape to react to orientation changes

    init(url: URL, isLandscape: Bool) {
        self.url = url
        self.isLandscape = isLandscape
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        // Configure QLPreviewController for optimal display
        controller.view.backgroundColor = .clear
        controller.automaticallyAdjustsScrollViewInsets = true
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // Ensure the data source is up-to-date
        context.coordinator.parent = self
        uiViewController.dataSource = context.coordinator
        // Force reload of the preview to reflect new URL or orientation
        uiViewController.reloadData()
        // Trigger layout update to handle orientation changes
        uiViewController.view.setNeedsLayout()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        var parent: PDFPreviewView

        init(parent: PDFPreviewView) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as QLPreviewItem
        }
    }
}
