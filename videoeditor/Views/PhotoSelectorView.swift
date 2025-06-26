import SwiftUI
import PhotosUI

struct PhotoSelectorView: View {
    @Binding var selectedPickerItems: [PhotosPickerItem]
    
    var body: some View {
        PhotosPicker(
            selection: $selectedPickerItems,
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 4) {
                        Text("Select Photos")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text("Tap to begin creating your PDF")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: Color.blue.opacity(0.1), radius: 8, x: 0, y: 4)
                
                Spacer()
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: -40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
} 