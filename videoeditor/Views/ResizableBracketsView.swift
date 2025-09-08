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
    let isResizingDisabled: Bool
    let initialWidth: CGFloat
    let onDragEnded: ((CGRect) -> Void)?
    
    // Convenience initializer for backward compatibility
    init(captureRect: Binding<CGRect>, screenBounds: CGRect, isResizingDisabled: Bool, initialWidth: CGFloat) {
        self._captureRect = captureRect
        self.screenBounds = screenBounds
        self.isResizingDisabled = isResizingDisabled
        self.initialWidth = initialWidth
        self.onDragEnded = nil
    }
    
    init(captureRect: Binding<CGRect>, screenBounds: CGRect, isResizingDisabled: Bool, initialWidth: CGFloat, onDragEnded: ((CGRect) -> Void)?) {
        self._captureRect = captureRect
        self.screenBounds = screenBounds
        self.isResizingDisabled = isResizingDisabled
        self.initialWidth = initialWidth
        self.onDragEnded = onDragEnded
    }
    
    // Bracket styling
    private let bracketLength: CGFloat = 20.0
    private let bracketWidth: CGFloat = 5.0
    private let handleSize: CGFloat = 80.0 // Larger touchable area
    
    @State private var activeCorner: CornerPosition?
    
    private var crosshairOpacity: Double {
        if isResizingDisabled {
            return 0.5
        }
        return activeCorner == nil ? 1.0 : 0.0
    }
    
    var body: some View {
        ZStack {
            
            // Thin white border around capture area with rounded corners (drawn first, behind brackets)
     RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.05)) // White fill with 0.03 opacity
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.9), lineWidth: 0.5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                            .blur(radius: 1)
                    )
                    .shadow(color: Color.white.opacity(0.3), radius: 1, x: 0, y: 0)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            )
            .frame(width: captureRect.width, height: captureRect.height)
            .position(x: captureRect.midX, y: captureRect.midY)

            // Styled corner brackets with rounded corners and line caps (drawn on top)
            styledBracket(at: .topLeft)
            styledBracket(at: .topRight)
            styledBracket(at: .bottomLeft)
            styledBracket(at: .bottomRight)
            
            // Center crosshair for aiming
            Path { path in
                let crosshairSize: CGFloat = 20
                let center = CGPoint(x: captureRect.midX, y: captureRect.midY)
                path.move(to: CGPoint(x: center.x - crosshairSize / 2, y: center.y))
                path.addLine(to: CGPoint(x: center.x + crosshairSize / 2, y: center.y))
                path.move(to: CGPoint(x: center.x, y: center.y - crosshairSize / 2))
                path.addLine(to: CGPoint(x: center.x, y: center.y + crosshairSize / 2))
            }
            .stroke(Color.white, lineWidth: 1)
            .opacity(crosshairOpacity)
            .animation(.easeInOut(duration: 0.2), value: crosshairOpacity)
            
        }
        .contentShape(cornerHitTestShape()) // Updated to custom shape for targeted hit testing
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if activeCorner == nil {
                        activeCorner = corner(for: value.startLocation)
                    }
                    
                    if let activeCorner = activeCorner {
                        updateCaptureRect(for: activeCorner, dragValue: value)
                    }
                }
                .onEnded { _ in
                    activeCorner = nil
                    onDragEnded?(captureRect)
                }
        )
        .disabled(isResizingDisabled)
    }
    
    // Custom shape for hit testing only around corners
    private func cornerHitTestShape() -> some Shape {
        Path { path in
            let allCorners: [CornerPosition] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
            for corner in allCorners {
                let handlePosition = getCornerPosition(corner)
                let handleRect = CGRect(
                    x: handlePosition.x - handleSize / 2,
                    y: handlePosition.y - handleSize / 2,
                    width: handleSize,
                    height: handleSize
                )
                path.addRect(handleRect)
            }
        }
    }
    
    private func corner(for location: CGPoint) -> CornerPosition? {
        let allCorners: [CornerPosition] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        
        for corner in allCorners {
            let handlePosition = getCornerPosition(corner)
            let handleRect = CGRect(
                x: handlePosition.x - handleSize / 2,
                y: handlePosition.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
            if handleRect.contains(location) {
                return corner
            }
        }
        
        return nil
    }
    
    private func styledBracket(at corner: CornerPosition) -> some View {
        let position = getCornerPosition(corner)
        
        return BracketShape(corner: corner, length: bracketLength, cornerRadius: 8.0)
            .stroke(Color.white, style: StrokeStyle(lineWidth: bracketWidth, lineCap: .round, lineJoin: .round))
            .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
            .frame(width: bracketLength * 2, height: bracketLength * 2)
            .position(position)
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
        let bottomMargin: CGFloat = 290.0  // 290pt from bottom of device
        let sideMargin: CGFloat = 20.0     // Side padding
        
        // New constraint: bracket height can't be more than 1/3 of the device height
        let maxHeight = screenBounds.height / 3
        
        // Calculate the delta from the center for mirrored movement
        let deltaX = abs(newLocation.x - center.x)
        let deltaY = abs(newLocation.y - center.y)
        
        // Ensure minimum size constraints
        let constrainedDeltaX = max(deltaX, minWidth / 2)
        let constrainedDeltaY = max(deltaY, minHeight / 2)
        
        // Apply maximum constraints
        let maxDeltaX = initialWidth / 2
        let finalDeltaX = min(constrainedDeltaX, maxDeltaX)
        let finalDeltaY = min(constrainedDeltaY, maxHeight / 2) // Clamping by the new max height
        
        // Create new rect centered at the same point but with mirrored dimensions
        let newRect = CGRect(
            x: center.x - finalDeltaX,
            y: center.y - finalDeltaY,
            width: finalDeltaX * 2,
            height: finalDeltaY * 2
        )
        
        // Ensure the rectangle stays within screen bounds with proper margins and the new height constraint
        let constrainedRect = CGRect(
            x: max(sideMargin, min(newRect.minX, screenBounds.width - newRect.width - sideMargin)),
            y: max(topMargin, min(newRect.minY, screenBounds.height - bottomMargin - newRect.height)),
            width: min(newRect.width, initialWidth),
            height: min(newRect.height, maxHeight) // Applying the new height constraint
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
