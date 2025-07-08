import SwiftUI
import PhotosUI

struct PhotoSelectorView: View {
    @Binding var selectedPickerItems: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]
    @State private var showPremiumAlert = false
    @EnvironmentObject var iapManager: IAPManager
    @Environment(\.colorScheme) var colorScheme
    
    private let freeLimit = 3
    
    var body: some View {
        PhotosPicker(
            selection: $selectedPickerItems,
            maxSelectionCount: iapManager.isPremium ? nil : freeLimit,
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
                    
                    // Premium limitation indicator (shown after premium status determined)
                    if iapManager.didCheckPremium && !iapManager.isPremium {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.orange)
                                Text("Free: Up to \(freeLimit) photos")
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            
                            Button(action: {
                                // showPremiumAlert = true
                                NotificationCenter.default.post(name: NSNotification.Name("ShowPremiumView"), object: nil)
                            }) {
                                Text("Upgrade for unlimited photos")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    } else if iapManager.didCheckPremium {
                        // Premium user indicator
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.yellow)
                            Text("Premium: Unlimited photos")
                                .font(.caption.bold())
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.yellow.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
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
        .alert("Upgrade to Premium", isPresented: $showPremiumAlert) {
            Button("Upgrade") {
                // This would trigger the premium view
                NotificationCenter.default.post(name: NSNotification.Name("ShowPremiumView"), object: nil)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Upgrade to Premium to select unlimited photos and unlock all features!")
        }
        .onChange(of: selectedPickerItems) { newItems in
            // Check if user is trying to select more than the free limit
            if !iapManager.isPremium && selectedImages.count + newItems.count > freeLimit {
                showPremiumAlert = true
            }
        }
    }
} 