//
//  CameraWithBracketsView.swift
//  videoeditor
//
//  Created by Anthony Ho on 31/08/2025.
//

import SwiftUI

struct CameraWithBracketsView: View {
    @Binding var capturedImage: UIImage?
    @State private var captureRect: CGRect = {
        let screenBounds = UIScreen.main.bounds
        let screenWidth = screenBounds.width
        let screenHeight = screenBounds.height
        
        let rectWidth = screenWidth * 0.85  // 85% of screen width
        let rectHeight: CGFloat = 120.0
        
        // Center horizontally on screen
        let rectX = (screenWidth - rectWidth) / 2.0
        
        // Center vertically in the screen, then move up 50px
        let rectY = (screenHeight - rectHeight) / 2.0 - 40.0
        
        return CGRect(x: rectX, y: rectY, width: rectWidth, height: rectHeight)
    }()
    
    var body: some View {
        ZStack {
            // Camera view with overlay
            CameraView(capturedImage: $capturedImage, captureRect: $captureRect)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
            
            // Resizable brackets overlay
            ResizableBracketsView(
                captureRect: $captureRect,
                screenBounds: UIScreen.main.bounds
            )
            .allowsHitTesting(true)
        }
    }
}
