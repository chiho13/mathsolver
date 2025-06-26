import SwiftUI
import UniformTypeIdentifiers

struct TrashDropDelegate: DropDelegate {
    @Binding var selectedImages: [UIImage]
    @Binding var currentDraggingIndex: Int?

    func performDrop(info: DropInfo) -> Bool {
        guard let currentDraggingIndex = currentDraggingIndex else {
            return false
        }
        
        selectedImages.remove(at: currentDraggingIndex)
        self.currentDraggingIndex = nil
        return true
    }
} 