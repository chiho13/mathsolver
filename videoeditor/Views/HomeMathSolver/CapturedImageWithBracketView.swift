import SwiftUI

struct ImageWithBracketView: View {
    let image: UIImage
    @Binding var captureRect: CGRect
    let isAnimatingCroppedArea: Bool
    @State private var showDotsView: Bool = false
    @Binding var currentImageOffset: CGSize
    @State private var currentImageScale: CGFloat = 1.0
    @GestureState private var gestureImageScale: CGFloat = 1.0
    @GestureState private var gestureImageOffset: CGSize = .zero

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let viewWidth = geometry.size.width
                let viewHeight = geometry.size.height
                let imageAspectRatio = image.size.width / image.size.height
                let scaledHeight = viewWidth / imageAspectRatio

                // Ensure the image is centered and scaled consistently
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: viewWidth, height: scaledHeight)
                    .position(x: viewWidth / 2, y: viewHeight / 2)
                    .offset(x: currentImageOffset.width + gestureImageOffset.width,
                            y: currentImageOffset.height + gestureImageOffset.height)
                    .scaleEffect(currentImageScale * gestureImageScale)
                    .gesture(
                        SimultaneousGesture(
                            DragGesture()
                                .updating($gestureImageOffset) { value, state, _ in
                                    state = value.translation
                                }
                                .onEnded { value in
                                    self.currentImageOffset.width += value.translation.width
                                    self.currentImageOffset.height += value.translation.height
                                },
                            MagnificationGesture()
                                .updating($gestureImageScale) { value, state, _ in
                                    state = 1 + (value - 1) * 0.75
                                }
                                .onEnded { value in
                                    self.currentImageScale *= (1 + (value - 1) * 0.75)
                                    self.currentImageScale = max(1.0, self.currentImageScale)
                                }
                        )
                    )
            }
            .clipped() // Ensure clipping is applied to the GeometryReader
            .ignoresSafeArea(.all)

            // Brackets view
            ResizableBracketsView(
                captureRect: $captureRect,
                screenBounds: UIScreen.main.bounds,
                isResizingDisabled: true,
                initialWidth: UIScreen.main.bounds.width * 0.88
            )

            // Use overlay to prevent layout impact from DotsAndScanAnimationView
        DotsAndScanAnimationView(captureRect: captureRect, isAnimating: isAnimatingCroppedArea)
                .opacity(showDotsView ? 1 : 0)
                .allowsHitTesting(false)
                .zIndex(1)
                
        }
        .animation(nil, value: showDotsView) // Disable implicit animations for showDotsView
        .onChange(of: isAnimatingCroppedArea) { _, isAnimating in
            if isAnimating {
                showDotsView = true
            } else {
                showDotsView = false // Remove delay to avoid timing issues
            }
        }
    }
}
