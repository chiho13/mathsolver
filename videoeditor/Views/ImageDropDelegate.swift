import SwiftUI
import UIKit

// MARK: - Drag & Drop Delegate for Reordering Images

struct ImageDropDelegate: DropDelegate {
    let index: Int
    @Binding var items: [UIImage]
    @Binding var currentDraggingIndex: Int?

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        guard let fromIndex = currentDraggingIndex else { return }
        if fromIndex != index {
            withAnimation {
                let item = items.remove(at: fromIndex)
                items.insert(item, at: index)
                currentDraggingIndex = index
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        currentDraggingIndex = nil
        return true
    }
} 