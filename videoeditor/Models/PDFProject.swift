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
    var imageDataArray: [String] // base64 encoded images
    
    init(title: String, isLandscape: Bool = false, photosPerPage: Int = 1, images: [UIImage] = [], showTitle: Bool = true) {
        self.id = UUID()
        self.title = title
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.isLandscape = isLandscape
        self.photosPerPage = photosPerPage
        self.showTitle = showTitle
        self.imageDataArray = images.compactMap { image in
            return image.jpegData(compressionQuality: 0.8)?.base64EncodedString()
        }
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
    
    // Helper method to update images
    func updateImages(_ newImages: [UIImage]) {
        self.imageDataArray = newImages.compactMap { image in
            return image.jpegData(compressionQuality: 0.8)?.base64EncodedString()
        }
        self.modifiedDate = Date()
    }
    
    // Helper method to add a single image
    func addImage(_ image: UIImage) {
        if let base64String = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() {
            self.imageDataArray.append(base64String)
            self.modifiedDate = Date()
        }
    }
    
    // Helper method to remove image at index
    func removeImage(at index: Int) {
        guard index >= 0 && index < imageDataArray.count else { return }
        imageDataArray.remove(at: index)
        self.modifiedDate = Date()
    }
    
    // Helper method to move image
    func moveImage(from source: Int, to destination: Int) {
        guard source >= 0 && source < imageDataArray.count,
              destination >= 0 && destination < imageDataArray.count else { return }
        let item = imageDataArray.remove(at: source)
        imageDataArray.insert(item, at: destination)
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