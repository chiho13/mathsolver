import SwiftUI

struct PhotoEditorView: View {
    let asset: EditableAsset
    let onDone: (EditableAsset?) -> Void

    @State private var image: UIImage
    @State private var rotationAngle: Angle = .zero

    init(asset: EditableAsset, onDone: @escaping (EditableAsset?) -> Void) {
        self.asset = asset
        self.onDone = onDone
        _image = State(initialValue: asset.image)
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top toolbar
                HStack {
                    Button("Cancel") {
                        onDone(nil)
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .medium))
                    
                    Spacer()
                    
                    Text("Edit Photo")
                        .foregroundColor(.white)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Spacer()
                    
                    Button("Done") {
                        saveChanges()
                    }
                    .foregroundColor(.accentColor)
                    .font(.system(size: 17, weight: .semibold))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Image display area
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(rotationAngle)
                        .animation(.easeInOut(duration: 0.3), value: rotationAngle)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                
                // Bottom toolbar
                HStack(spacing: 40) {
                    // Rotate Left Button
                    Button(action: {
                        withAnimation(.easeInOut) {
                            rotationAngle -= .degrees(90)
                        }
                    }) {
                        VStack {
                            Image(systemName: "rotate.left")
                                .font(.system(size: 20))
                            Text("Rotate")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                    }
                    
                    // Reset Button
                    Button(action: {
                        withAnimation(.easeInOut) {
                            rotationAngle = .zero
                        }
                    }) {
                        VStack {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 20))
                            Text("Reset")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.5))
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveChanges() {
        if rotationAngle != .zero {
            let rotatedImage = image.rotated(by: rotationAngle) ?? image
            let resultAsset = EditableAsset(image: rotatedImage, index: asset.index)
            onDone(resultAsset)
        } else {
            onDone(asset) // No changes
        }
    }
}

extension UIImage {
    func rotated(by angle: Angle) -> UIImage? {
        let radians = CGFloat(angle.radians)
        
        var newSize = CGRect(origin: .zero, size: self.size).applying(CGAffineTransform(rotationAngle: radians)).size
        // Trim off the extremely small float value to prevent core graphics from rounding up to a larger size when converting to integers
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: radians)
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
} 

