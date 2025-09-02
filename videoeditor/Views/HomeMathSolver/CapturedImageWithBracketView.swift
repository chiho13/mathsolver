import SwiftUI

struct CapturedImageWithBracketView: View {
    let image: UIImage
    @Binding var captureRect: CGRect
    let isAnimatingCroppedArea: Bool
    @State private var showDotsView: Bool = false

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
                .clipped()
            ResizableBracketsView(
                captureRect: $captureRect,
                screenBounds: UIScreen.main.bounds,
                isResizingDisabled: true,
                initialWidth: UIScreen.main.bounds.width * 0.88
            )
            if showDotsView {
                DotsAndScanAnimationView(captureRect: captureRect, isAnimating: isAnimatingCroppedArea)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .onChange(of: isAnimatingCroppedArea) { _, isAnimating in
            if isAnimating {
                showDotsView = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showDotsView = false
                }
            }
        }
    }
}
