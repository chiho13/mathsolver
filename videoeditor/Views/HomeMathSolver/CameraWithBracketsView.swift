//
//  CameraWithBracketsView.swift
//  videoeditor
//
//  Created by Anthony Ho on 31/08/2025.
//

import SwiftUI

struct CameraWithBracketsView: View {
    @Binding var capturedImage: UIImage?
    @Binding var originalImage: UIImage?
    @ObservedObject var viewModel: VisionViewModel
    @Binding var triggerCapture: Bool
    @Binding var captureRect: CGRect
    @Binding var freezeImage: UIImage?
    @Binding var isImageAtTop: Bool
    @State private var showDotsView: Bool = false
    
    var body: some View {
        ZStack {
            // Camera view with overlay
            CameraView(capturedImage: $capturedImage, originalImage: $originalImage, captureRect: $captureRect, viewModel: viewModel, triggerCapture: $triggerCapture, freezeImage: $freezeImage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
              // Force update when animation state changes
            
               if let capturedImage = capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: captureRect.width, height: captureRect.height)
                    .position(x: captureRect.midX, y: captureRect.midY)
                    .clipped()
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }

            // Resizable brackets overlay
            ResizableBracketsView(
                captureRect: $captureRect,
                screenBounds: UIScreen.main.bounds,
                isResizingDisabled: viewModel.isAnimatingCroppedArea,
                initialWidth: UIScreen.main.bounds.width * 0.88
            )
            
            // Animation overlay - appears above brackets
            if showDotsView {
                DotsAndScanAnimationView(captureRect: captureRect, isAnimating: viewModel.isAnimatingCroppedArea)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .offset(y: isImageAtTop ? -((UIScreen.main.bounds.height / 3) - 120.0) : 0)
        .animation(.easeInOut(duration: 0.5), value: isImageAtTop)
        .onChange(of: viewModel.isAnimatingCroppedArea) { _, isAnimating in
            if isAnimating {
                showDotsView = true
            } else {
                // Delay hiding the view to allow for its exit animation.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showDotsView = false
                }
            }
        }
    }
}
