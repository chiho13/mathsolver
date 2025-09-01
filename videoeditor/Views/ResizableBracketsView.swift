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
            // Styled corner brackets with rounded corners and line caps
            styledBracket(at: .topLeft)
            styledBracket(at: .topRight)
            styledBracket(at: .bottomLeft)
            styledBracket(at: .bottomRight)
            
            // Thin white border around capture area with rounded corners
            RoundedRectangle(cornerRadius: 8)
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
    
    private func styledBracket(at corner: CornerPosition) -> some View {
        let position = getCornerPosition(corner)
        
        return BracketShape(corner: corner, length: bracketLength, cornerRadius: 8.0)
            .stroke(Color.white, style: StrokeStyle(lineWidth: bracketWidth, lineCap: .round, lineJoin: .round))
            .frame(width: bracketLength * 2, height: bracketLength * 2)
            .position(position)
    }
    
    private func cornerHandle(at corner: CornerPosition) -> some View {
        let position = getCornerPosition(corner)
        
        return Rectangle()
            .fill(Color.clear)
            .frame(width: handleSize, height: handleSize)
            .position(position)
            .contentShape(Rectangle()) // Ensures the entire rectangle area is touchable
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

struct BracketShape: Shape {
    let corner: CornerPosition
    let length: CGFloat
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        switch corner {
        case .topLeft:
            // Horizontal line extending right from corner
            path.move(to: CGPoint(x: center.x + length, y: center.y))
            path.addLine(to: CGPoint(x: center.x + cornerRadius, y: center.y))
            path.addQuadCurve(
                to: CGPoint(x: center.x, y: center.y + cornerRadius),
                control: CGPoint(x: center.x, y: center.y)
            )
            // Vertical line extending down from corner
            path.addLine(to: CGPoint(x: center.x, y: center.y + length))
            
        case .topRight:
            // Horizontal line extending left from corner
            path.move(to: CGPoint(x: center.x - length, y: center.y))
            path.addLine(to: CGPoint(x: center.x - cornerRadius, y: center.y))
            path.addQuadCurve(
                to: CGPoint(x: center.x, y: center.y + cornerRadius),
                control: CGPoint(x: center.x, y: center.y)
            )
            // Vertical line extending down from corner
            path.addLine(to: CGPoint(x: center.x, y: center.y + length))
            
        case .bottomLeft:
            // Vertical line extending up from corner
            path.move(to: CGPoint(x: center.x, y: center.y - length))
            path.addLine(to: CGPoint(x: center.x, y: center.y - cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: center.x + cornerRadius, y: center.y),
                control: CGPoint(x: center.x, y: center.y)
            )
            // Horizontal line extending right from corner
            path.addLine(to: CGPoint(x: center.x + length, y: center.y))
            
        case .bottomRight:
            // Vertical line extending up from corner
            path.move(to: CGPoint(x: center.x, y: center.y - length))
            path.addLine(to: CGPoint(x: center.x, y: center.y - cornerRadius))
            path.addQuadCurve(
                to: CGPoint(x: center.x - cornerRadius, y: center.y),
                control: CGPoint(x: center.x, y: center.y)
            )
            // Horizontal line extending left from corner
            path.addLine(to: CGPoint(x: center.x - length, y: center.y))
        }
        
        return path
    }
}



