import SwiftUI
import PDFKit
import UIKit

/// SwiftUI wrapper around `PDFView` that allows the user to add **text annotations** on tap.
///
/// Usage example:
/// ```swift
/// @State private var addTextMode = false
/// PDFAnnotationView(url: pdfURL, addTextMode: $addTextMode)
///     .toolbar {
///         Toggle(isOn: $addTextMode) {
///             Image(systemName: "plus.bubble")
///         }
///     }
/// ```
struct PDFAnnotationView: UIViewRepresentable {
    /// Either pass an URL or an existing `PDFDocument`.
    let document: PDFDocument
    /// When `true`, a tap inserts a text annotation at the tapped location.
    @Binding var addTextMode: Bool

    /// Called right before the add / edit text alert is presented so the host can adjust UI (e.g. hide overlays).
    var onShowTextAlert: () -> Void = {}

    init(url: URL, addTextMode: Binding<Bool>, onShowTextAlert: @escaping () -> Void = {}) {
        self.document = PDFDocument(url: url) ?? PDFDocument()
        self._addTextMode = addTextMode
        self.onShowTextAlert = onShowTextAlert
    }

    init(document: PDFDocument, addTextMode: Binding<Bool>, onShowTextAlert: @escaping () -> Void = {}) {
        self.document = document
        self._addTextMode = addTextMode
        self.onShowTextAlert = onShowTextAlert
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.displayMode = .singlePageContinuous
        pdfView.usePageViewController(true)

        // Tap gesture for adding or editing annotations
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        pdfView.addGestureRecognizer(tap)

        // Pan gesture for moving existing annotations
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        // Avoid interference: require tap to fail before pan recognises (so short taps don't move)
        pan.require(toFail: tap)
        pdfView.addGestureRecognizer(pan)

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Nothing extra to update; the coordinator consults `addTextMode` each tap.
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        let parent: PDFAnnotationView

        init(parent: PDFAnnotationView) {
            self.parent = parent
            super.init()
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let pdfView = gesture.view as? PDFView else { return }

            let location = gesture.location(in: pdfView)
            guard let page = pdfView.page(for: location, nearest: true) else { return }
            let pageLocation = pdfView.convert(location, to: page)

            // Check if an annotation already exists at this point (within a small tolerance)
            if let existing = page.annotations.first(where: { $0.bounds.insetBy(dx: -5, dy: -5).contains(pageLocation) }) {
                presentEditAlert(for: existing, on: page, pdfView: pdfView)
                return
            }

            // If addTextMode is enabled, add a new annotation
            guard parent.addTextMode else { return }

            presentAddAlert(at: pageLocation, on: page, pdfView: pdfView)
        }

        // MARK: - Gesture for moving annotations

        private var movingAnnotation: PDFAnnotation?
        private var lastPanLocation: CGPoint = .zero

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let pdfView = gesture.view as? PDFView else { return }

            let location = gesture.location(in: pdfView)
            guard let page = pdfView.page(for: location, nearest: true) else { return }
            let pageLocation = pdfView.convert(location, to: page)

            switch gesture.state {
            case .began:
                // identify annotation at start
                movingAnnotation = page.annotations.first(where: { $0.bounds.insetBy(dx: -5, dy: -5).contains(pageLocation) })
                lastPanLocation = pageLocation
            case .changed:
                guard let annotation = movingAnnotation else { return }
                let dx = pageLocation.x - lastPanLocation.x
                let dy = pageLocation.y - lastPanLocation.y
                var newBounds = annotation.bounds
                newBounds.origin.x += dx
                newBounds.origin.y += dy
                annotation.bounds = newBounds
                lastPanLocation = pageLocation
            default:
                movingAnnotation = nil
            }
        }

        // MARK: - Helpers

        private func presentAddAlert(at pageLocation: CGPoint, on page: PDFPage, pdfView: PDFView) {
            parent.onShowTextAlert()
            let alert = UIAlertController(title: "Add Text", message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "Annotation text"
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
                guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }

                let annotation = self.createAnnotation(text: text, at: pageLocation)
                page.addAnnotation(annotation)
            })

            topController(from: pdfView)?.present(alert, animated: true)
        }

        private func presentEditAlert(for annotation: PDFAnnotation, on page: PDFPage, pdfView: PDFView) {
            parent.onShowTextAlert()
            let alert = UIAlertController(title: "Edit Text", message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                // Remove leading space when showing text for editing
                let displayText = annotation.contents?.hasPrefix(" ") == true ? 
                    String(annotation.contents!.dropFirst()) : annotation.contents
                textField.text = displayText
            }
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                page.removeAnnotation(annotation)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
                guard let newText = alert.textFields?.first?.text, !newText.isEmpty else { return }
                // Add leading space back when saving
                let paddedText = " \(newText)"
                annotation.contents = paddedText

                self.resizeAnnotation(annotation, toFit: newText)
            })

            topController(from: pdfView)?.present(alert, animated: true)
        }

        private func createAnnotation(text: String, at location: CGPoint) -> PDFAnnotation {
            let font = UIFont.systemFont(ofSize: 14) // system sans-serif
            // Estimate text size
            let attributed = NSAttributedString(string: text, attributes: [
                .font: font
            ])
            var size = attributed.size()
            let padding: CGFloat = 6
            size.width += padding * 2
            size.height += padding * 2

            // Offset so text appears centered in rect after padding
            var origin = location
            origin.x -= padding
            origin.y -= padding

            let annotation = PDFAnnotation(bounds: CGRect(origin: origin, size: size), forType: .freeText, withProperties: nil)
            annotation.contents = text
            annotation.font = font
            annotation.fontColor = .label
            // White background at 50% opacity
            annotation.interiorColor = UIColor.white.withAlphaComponent(0.5)
            // Remove border stroke
            annotation.border = PDFBorder()
            annotation.border?.lineWidth = 0
            
            // Set text alignment to ensure proper padding
            annotation.alignment = .left
            
            // Add padding to the text content itself by prefixing with spaces
            // This ensures the text doesn't start right at the edge
            let paddedText = " \(text)"
            annotation.contents = paddedText
            
            return annotation
        }

        // Helper to resize annotation bounds with padding respecting current origin
        private func resizeAnnotation(_ annotation: PDFAnnotation, toFit text: String) {
            let font = annotation.font ?? UIFont.systemFont(ofSize: 14)
            // Use padded text for size calculation to match createAnnotation behavior
            let paddedText = " \(text)"
            let attributed = NSAttributedString(string: paddedText, attributes: [.font: font])
            var size = attributed.size()
            let padding: CGFloat = 6
            size.width += padding * 2
            size.height += padding * 2

            var bounds = annotation.bounds
            bounds.size = size
            annotation.bounds = bounds
        }

        private func topController(from view: UIView) -> UIViewController? {
            var responder: UIResponder? = view
            while responder != nil {
                if let vc = responder as? UIViewController {
                    return vc
                }
                responder = responder?.next
            }
            return nil
        }
    }
} 