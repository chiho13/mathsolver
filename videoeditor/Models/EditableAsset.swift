import SwiftUI

struct EditableAsset: Identifiable {
    let id = UUID()
    let image: UIImage
    let originalImage: UIImage
    let index: Int
    
    // Computed property to check if image has been modified
    var isModified: Bool {
        // Compare image data instead of object references for more reliable comparison
        guard let imageData = image.pngData(),
              let originalData = originalImage.pngData() else {
            return false // If we can't get data, assume not modified
        }
        return imageData != originalData
    }
    
    // Initialize with a single image (original and current are the same)
    init(image: UIImage, index: Int) {
        self.image = image
        self.originalImage = image
        self.index = index
    }
    
    // Initialize with both original and current images
    init(image: UIImage, originalImage: UIImage, index: Int) {
        self.image = image
        self.originalImage = originalImage
        self.index = index
    }
    
    // Create a new asset with modified image but same original
    func withModifiedImage(_ newImage: UIImage) -> EditableAsset {
        return EditableAsset(image: newImage, originalImage: originalImage, index: index)
    }
    
    // Revert to original image
    func reverted() -> EditableAsset {
        return EditableAsset(image: originalImage, originalImage: originalImage, index: index)
    }
} 