import Foundation
import SwiftData
import UIKit

@Model
class PDFProject {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdDate: Date
    var modifiedDate: Date
    var isLandscape: Bool
    var photosPerPage: Int
    var showTitle: Bool
    var imageDataArray: [String] // base64 encoded current images
    var originalImageDataArray: [String]? // base64 encoded original images - optional for backward compatibility
    
    init(title: String, isLandscape: Bool = false, photosPerPage: Int = 1, images: [UIImage] = [], showTitle: Bool = true) {
        self.id = UUID()
        self.title = title
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.isLandscape = isLandscape
        self.photosPerPage = photosPerPage
        self.showTitle = showTitle
        let base64Images = images.compactMap { image in
            return image.jpegData(compressionQuality: 0.8)?.base64EncodedString()
        }
        self.imageDataArray = base64Images
        self.originalImageDataArray = base64Images // Initially, original and current are the same
    }
    
    // Computed property to convert base64 back to UIImages
    var images: [UIImage] {
        return imageDataArray.compactMap { base64String in
            guard let data = Data(base64Encoded: base64String),
                  let image = UIImage(data: data) else {
                return nil
            }
            return image
        }
    }
    
    // Computed property to get original images
    var originalImages: [UIImage] {
        // For backward compatibility, if originalImageDataArray is nil, use current images
        let originalData = originalImageDataArray ?? imageDataArray
        return originalData.compactMap { base64String in
            guard let data = Data(base64Encoded: base64String),
                  let image = UIImage(data: data) else {
                return nil
            }
            return image
        }
    }
    
    // Check if any image has been modified
    var hasModifiedImages: Bool {
        guard let originalData = originalImageDataArray else { return false }
        return imageDataArray != originalData
    }
    
    // Check if specific image has been modified
    func isImageModified(at index: Int) -> Bool {
        guard let originalData = originalImageDataArray,
              index >= 0 && index < imageDataArray.count && index < originalData.count else { return false }
        return imageDataArray[index] != originalData[index]
    }
    
    // Helper method to ensure originalImageDataArray is initialized
    private func ensureOriginalImagesInitialized() {
        if originalImageDataArray == nil || originalImageDataArray?.isEmpty == true {
            originalImageDataArray = imageDataArray
        }
    }
    
    // Helper method to update images (maintains originals)
    func updateImages(_ newImages: [UIImage]) {
        let newImageData = newImages.compactMap { image in
            return image.jpegData(compressionQuality: 0.8)?.base64EncodedString()
        }
        
        // If this is the first time images are being added (both arrays are empty),
        // treat these as the original images
        if imageDataArray.isEmpty && (originalImageDataArray?.isEmpty != false) {
            self.imageDataArray = newImageData
            self.originalImageDataArray = newImageData
        } else {
            // Normal update - preserve existing originals
            ensureOriginalImagesInitialized()
            self.imageDataArray = newImageData
        }
        
        self.modifiedDate = Date()
    }
    
    // Helper method to update a single image at index (maintains original)
    func updateImage(at index: Int, with newImage: UIImage) {
        guard index >= 0 && index < imageDataArray.count else { return }
        ensureOriginalImagesInitialized()
        if let base64String = newImage.jpegData(compressionQuality: 0.8)?.base64EncodedString() {
            imageDataArray[index] = base64String
            self.modifiedDate = Date()
        }
    }
    
    // Helper method to revert a single image to original
    func revertImage(at index: Int) {
        guard let originalData = originalImageDataArray,
              index >= 0 && index < imageDataArray.count && index < originalData.count else { return }
        imageDataArray[index] = originalData[index]
        self.modifiedDate = Date()
    }
    
    // Helper method to revert all images to original
    func revertAllImages() {
        guard let originalData = originalImageDataArray else { return }
        imageDataArray = originalData
        self.modifiedDate = Date()
    }

    // Helper method to add a single image
    func addImage(_ image: UIImage) {
        ensureOriginalImagesInitialized()
        if let base64String = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() {
            self.imageDataArray.append(base64String)
            self.originalImageDataArray?.append(base64String) // New images are their own originals
            self.modifiedDate = Date()
        }
    }
    
    // Helper method to remove image at index
    func removeImage(at index: Int) {
        guard index >= 0 && index < imageDataArray.count else { return }
        imageDataArray.remove(at: index)
        if let originalData = originalImageDataArray, index < originalData.count {
            originalImageDataArray?.remove(at: index)
        }
        self.modifiedDate = Date()
    }
    
    // Helper method to move image
    func moveImage(from source: Int, to destination: Int) {
        guard source >= 0 && source < imageDataArray.count,
              destination >= 0 && destination < imageDataArray.count else { return }
        let currentItem = imageDataArray.remove(at: source)
        imageDataArray.insert(currentItem, at: destination)
        
        // Also move the original if it exists
        if let originalData = originalImageDataArray,
           source < originalData.count && destination < originalData.count {
            let originalItem = originalImageDataArray!.remove(at: source)
            originalImageDataArray!.insert(originalItem, at: destination)
        }
        self.modifiedDate = Date()
    }
    
    // Helper method to update configuration
    func updateConfiguration(title: String? = nil, isLandscape: Bool? = nil, photosPerPage: Int? = nil, showTitle: Bool? = nil) {
        if let title = title {
            self.title = title
        }
        if let isLandscape = isLandscape {
            self.isLandscape = isLandscape
        }
        if let photosPerPage = photosPerPage {
            self.photosPerPage = photosPerPage
        }
        if let showTitle = showTitle {
            self.showTitle = showTitle
        }
        self.modifiedDate = Date()
    }
} 

