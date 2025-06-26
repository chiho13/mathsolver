import SwiftUI
import QuickLook

struct PDFPreviewView: UIViewControllerRepresentable {
    let url: URL
    let isLandscape: Bool // Add isLandscape to react to orientation changes
    @Binding var shouldScrollToBottom: Bool

    init(url: URL, isLandscape: Bool, shouldScrollToBottom: Binding<Bool>) {
        self.url = url
        self.isLandscape = isLandscape
        self._shouldScrollToBottom = shouldScrollToBottom
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
        
        // Handle scroll to bottom when triggered
        if shouldScrollToBottom {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.scrollToBottom(in: uiViewController.view)
                shouldScrollToBottom = false // Reset the trigger
            }
        }
    }
    
    // Helper to find scroll view in QLPreviewController
    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        for subview in view.subviews {
            if let scrollView = findScrollView(in: subview) {
                return scrollView
            }
        }
        return nil
    }
    
    // Function to scroll to bottom
    private func scrollToBottom(in view: UIView) {
        if let scrollView = findScrollView(in: view) {
            let bottomOffset = CGPoint(x: 0, y: max(0, scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom))
            scrollView.setContentOffset(bottomOffset, animated: true)
        }
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
