//
//  ResizableBracketsView.swift
//  videoeditor
//
//  Created by Anthony Ho on 31/08/2025.
//

import SwiftUI

struct ResizableBracketsView: View {
    @Binding var captureRect: CGRect
    let screenBounds: CGRect
    
    // Bracket styling
    private let bracketLength: CGFloat = 20.0
    private let bracketWidth: CGFloat = 4.0
    private let handleSize: CGFloat = 80.0 // Larger touchable area
    
    var body: some View {
        ZStack {
            // Simple white rectangles for brackets - just to test visibility
            // Top-left bracket
            Rectangle()
                .fill(Color.white)
                .frame(width: bracketLength, height: bracketWidth)
                .position(x: captureRect.minX + bracketLength/2, y: captureRect.minY)
            
            Rectangle()
                .fill(Color.white)
                .frame(width: bracketWidth, height: bracketLength)
                .position(x: captureRect.minX, y: captureRect.minY + bracketLength/2)
            
            // Top-right bracket
            Rectangle()
                .fill(Color.white)
                .frame(width: bracketLength, height: bracketWidth)
                .position(x: captureRect.maxX - bracketLength/2, y: captureRect.minY)
            
            Rectangle()
                .fill(Color.white)
                .frame(width: bracketWidth, height: bracketLength)
                .position(x: captureRect.maxX, y: captureRect.minY + bracketLength/2)
            
            // Bottom-left bracket
            Rectangle()
                .fill(Color.white)
                .frame(width: bracketLength, height: bracketWidth)
                .position(x: captureRect.minX + bracketLength/2, y: captureRect.maxY)
            
            Rectangle()
                .fill(Color.white)
                .frame(width: bracketWidth, height: bracketLength)
                .position(x: captureRect.minX, y: captureRect.maxY - bracketLength/2)
            
            // Bottom-right bracket
            Rectangle()
                .fill(Color.white)
                .frame(width: bracketLength, height: bracketWidth)
                .position(x: captureRect.maxX - bracketLength/2, y: captureRect.maxY)
            
            Rectangle()
                .fill(Color.white)
                .frame(width: bracketWidth, height: bracketLength)
                .position(x: captureRect.maxX, y: captureRect.maxY - bracketLength/2)
            
            // Thin white border around capture area
            Rectangle()
                .stroke(Color.white, lineWidth: 1)
                .frame(width: captureRect.width, height: captureRect.height)
                .position(x: captureRect.midX, y: captureRect.midY)
            
            // Corner handles for dragging (invisible but touchable)
            cornerHandle(at: .topLeft)
            cornerHandle(at: .topRight)
            cornerHandle(at: .bottomLeft)
            cornerHandle(at: .bottomRight)
        }
    }
    
    private func cornerHandle(at corner: CornerPosition) -> some View {
        let position = getCornerPosition(corner)
        
        return Circle()
            .fill(Color.clear) // Completely invisible but still touchable
            .frame(width: handleSize, height: handleSize)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        updateCaptureRect(for: corner, dragValue: value)
                    }
            )
    }
    
    private func getCornerPosition(_ corner: CornerPosition) -> CGPoint {
        switch corner {
        case .topLeft:
            return CGPoint(x: captureRect.minX, y: captureRect.minY)
        case .topRight:
            return CGPoint(x: captureRect.maxX, y: captureRect.minY)
        case .bottomLeft:
            return CGPoint(x: captureRect.minX, y: captureRect.maxY)
        case .bottomRight:
            return CGPoint(x: captureRect.maxX, y: captureRect.maxY)
        }
    }
    
    private func updateCaptureRect(for corner: CornerPosition, dragValue: DragGesture.Value) {
        let newLocation = dragValue.location
        let center = CGPoint(x: captureRect.midX, y: captureRect.midY)
        let minWidth: CGFloat = 100.0
        let minHeight: CGFloat = 50.0
        
        // Define maximum constraints based on device position
        let topMargin: CGFloat = 200.0     // 200pt from top of device
        let bottomMargin: CGFloat = 250.0  // 250pt from bottom of device
        let sideMargin: CGFloat = 20.0     // Side padding
        
        // Calculate maximum available height
        let maxAvailableHeight = screenBounds.height - topMargin - bottomMargin
        
        // Calculate the delta from the center for mirrored movement
        let deltaX = abs(newLocation.x - center.x)
        let deltaY = abs(newLocation.y - center.y)
        
        // Ensure minimum size constraints
        let constrainedDeltaX = max(deltaX, minWidth / 2)
        let constrainedDeltaY = max(deltaY, minHeight / 2)
        
        // Apply maximum height constraint
        let maxDeltaY = maxAvailableHeight / 2
        let finalDeltaX = constrainedDeltaX
        let finalDeltaY = min(constrainedDeltaY, maxDeltaY)
        
        // Create new rect centered at the same point but with mirrored dimensions
        let newRect = CGRect(
            x: center.x - finalDeltaX,
            y: center.y - finalDeltaY,
            width: finalDeltaX * 2,
            height: finalDeltaY * 2
        )
        
        // Ensure the rectangle stays within screen bounds with proper margins
        let constrainedRect = CGRect(
            x: max(sideMargin, min(newRect.minX, screenBounds.width - newRect.width - sideMargin)),
            y: max(topMargin, min(newRect.minY, screenBounds.height - bottomMargin - newRect.height)),
            width: min(newRect.width, screenBounds.width - 2 * sideMargin),
            height: min(newRect.height, maxAvailableHeight)
        )
        
        captureRect = constrainedRect
    }
}

enum CornerPosition {
    case topLeft, topRight, bottomLeft, bottomRight
}



