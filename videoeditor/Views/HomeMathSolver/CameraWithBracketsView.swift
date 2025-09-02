//
//  CameraWithBracketsView.swift
//  videoeditor
//
//  Created by Anthony Ho on 31/08/2025.
//

import SwiftUI

struct CameraWithBracketsView: View {
    @Binding var capturedImage: UIImage?
    @ObservedObject var viewModel: VisionViewModel
    @Binding var triggerCapture: Bool
    @State private var showDotsView: Bool = false
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
            CameraView(capturedImage: $capturedImage, captureRect: $captureRect, viewModel: viewModel, triggerCapture: $triggerCapture)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
                .id(viewModel.isAnimatingCroppedArea) // Force update when animation state changes
            
            // Resizable brackets overlay
            ResizableBracketsView(
                captureRect: $captureRect,
                screenBounds: UIScreen.main.bounds,
                isResizingDisabled: viewModel.isAnimatingCroppedArea,
                initialWidth: UIScreen.main.bounds.width * 0.85
            )
            .allowsHitTesting(true)
            
            // Animation overlay - appears above brackets
            if showDotsView {
                PulsingDotsView(captureRect: captureRect, viewModel: viewModel)
                    .allowsHitTesting(false) // Don't block touches
                    .transition(.opacity)
            }
        }
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

// SwiftUI view for pulsing dots animation
struct PulsingDotsView: View {
    let captureRect: CGRect
    @ObservedObject var viewModel: VisionViewModel
    // Animation state
    @State private var dotPositions: [CGPoint] = []
    @State private var dotScales: [CGFloat] = []
    @State private var animationPhases: [Double] = []
    @State private var waveDriver: Double = 0.0
    
    // Scan line state
    @State private var scanLineOffset: CGFloat = 0
    @State private var scanLineOpacity: Double = 1.0
    @State private var showScanLine: Bool = true
    @State private var showDots: Bool = false
    
    @State private var numberOfDots: Int = 12
    private let dotDensity: CGFloat = 0.00025
    private let dotSize: CGFloat = 5.0
    
    var body: some View {
        ZStack {
            // Vertical scanning line that fades as it moves
            if showScanLine {
                Rectangle()
                    .fill(Color.white)
                    .opacity(scanLineOpacity)
                    .frame(width: 4, height: captureRect.height)
                    .position(
                        x: captureRect.origin.x + scanLineOffset,
                        y: captureRect.origin.y + captureRect.height / 2
                    )
            }
            
            // Pulsing dots (shown after scan line completes)
            if showDots {
                ForEach(0..<numberOfDots, id: \.self) { index in
                    if index < dotPositions.count {
                        Circle()
                            .fill(Color.white)
                            .frame(width: dotSize, height: dotSize)
                            .opacity(0.9)
                            .scaleEffect(dotScales[index] * (1.0 + 0.3 * abs(sin(animationPhases[index]))))
                            .position(dotPositions[index])
                            .animation(.none, value: dotPositions[index]) // Don't animate position changes
                    }
                }
            }
        }
        .onAppear {
            recalculateDotCount()
            startScanLineAnimation()
        }
        .onChange(of: captureRect) { _, _ in
            recalculateDotCount()
            // Restart scan if capture rect changes
            resetAnimation()
        }
        .onChange(of: viewModel.isAnimatingCroppedArea) { _, isAnimating in
            if !isAnimating {
                withAnimation(.easeIn(duration: 0.3)) {
                    dotScales = Array(repeating: 0.0, count: numberOfDots)
                }
            }
        }
    }

    private func recalculateDotCount() {
        let area = captureRect.width * captureRect.height
        // Ensure at least 12 dots, and not too many, for performance and aesthetics
        let calculatedDots = max(16, Int(area * dotDensity))
        numberOfDots = min(calculatedDots, 50) // Cap at 50 dots
    }
    
    private func generateRandomPositions() {
        // --- Dynamic Padding Calculation ---
        let minHeightForPadding: CGFloat = 60.0
        let basePadding: CGFloat = 5.0 // Padding when height is at its minimum
        let additionalPaddingFactor: CGFloat = 0.1 // How much padding to add for each point of height increase

        let heightAboveMin = max(0, captureRect.height - minHeightForPadding)
        var calculatedPadding = basePadding + (heightAboveMin * additionalPaddingFactor)

        // Ensure padding doesn't consume the entire rect
        let maxAllowedPadding = min(captureRect.width, captureRect.height) / 3.0
        calculatedPadding = min(calculatedPadding, maxAllowedPadding)
        // --- End of Dynamic Padding Calculation ---

        let usableRect = CGRect(
            x: captureRect.origin.x + calculatedPadding,
            y: captureRect.origin.y + calculatedPadding,
            width: captureRect.width - (calculatedPadding * 2),
            height: captureRect.height - (calculatedPadding * 2)
        )
        
        guard numberOfDots > 0 else {
            dotPositions = []
            animationPhases = []
            return
        }

        // --- New Spacing Algorithm ---
        var newPositions: [CGPoint] = []
        var attempts = 0
        // Adjust minSpacing based on dot count for evenness
        let area = usableRect.width * usableRect.height
        
        // Add a modifier to reduce spacing when the rect is squashed vertically
        let defaultHeight: CGFloat = 120.0
        let heightFactor = min(1.0, captureRect.height / defaultHeight)
        let spacingModifier = (heightFactor * 0.4) + 0.6 // Ranges from 0.6 to 1.0

        let minSpacing = sqrt(area / CGFloat(numberOfDots)) * 0.7 * spacingModifier
        let maxAttempts = numberOfDots * 100

        // We will manually place the first and last dots, so generate N-2 random ones.
        let randomDotsToGenerate = max(0, numberOfDots - 2)

        while newPositions.count < randomDotsToGenerate && attempts < maxAttempts {
            let candidateX = CGFloat.random(in: usableRect.minX...usableRect.maxX)
            let candidateY = CGFloat.random(in: usableRect.minY...usableRect.maxY)
            let candidatePoint = CGPoint(x: candidateX, y: candidateY)
            
            var isFarEnough = true
            for existingPoint in newPositions {
                let distance = hypot(candidatePoint.x - existingPoint.x, candidatePoint.y - existingPoint.y)
                if distance < minSpacing {
                    isFarEnough = false
                    break
                }
            }
            
            if isFarEnough {
                newPositions.append(candidatePoint)
            }
            
            attempts += 1
        }
        
        // Add the anchor dots for the start and end of the wave
        if numberOfDots >= 2 {
            let leftAnchor = CGPoint(x: usableRect.minX, y: usableRect.midY)
            let rightAnchor = CGPoint(x: usableRect.maxX, y: usableRect.midY)
            newPositions.append(leftAnchor)
            newPositions.append(rightAnchor)
        }
        
        let remaining = numberOfDots - newPositions.count
        if remaining > 0 {
            for _ in 0..<remaining {
                let randomPoint = CGPoint(
                    x: CGFloat.random(in: usableRect.minX...usableRect.maxX),
                    y: CGFloat.random(in: usableRect.minY...usableRect.maxY)
                )
                newPositions.append(randomPoint)
            }
        }
        
        // --- End of New Algorithm ---
        
        dotPositions = newPositions
        
        // Initialize random animation phases
        animationPhases = (0..<numberOfDots).map { _ in
            Double.random(in: 0...Double.pi * 2)
        }
    }
    
    private func startScanLineAnimation() {
        // Reset states
        showScanLine = true
        showDots = false
        scanLineOffset = 0
        scanLineOpacity = 1.0
        
        generateRandomPositions()
        
        // Start scan line animation: move left-to-right and fade out simultaneously
        withAnimation(.linear(duration: 0.3)) {
            scanLineOffset = captureRect.width
            scanLineOpacity = 0.0
        }
        
        // After scan line animation completes, hide it and show dots
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showScanLine = false
            showDots = true
            startDotLifecycleAnimation()
        }
    }
    
    private func resetAnimation() {
        showScanLine = true
        showDots = false
        scanLineOffset = 0
        scanLineOpacity = 1.0
        dotScales = Array(repeating: 0.0, count: numberOfDots)
        startScanLineAnimation()
    }
    
    private func startDotLifecycleAnimation() {
        // Generate positions for dots
        generateRandomPositions()
        
        // Start with dots at scale 0
        dotScales = Array(repeating: 0.0, count: numberOfDots)
        
        // Phase 1: Grow from 0 to 1.0 (appear)
        withAnimation(.easeOut(duration: 0.3)) {
            dotScales = (0..<numberOfDots).map { _ in 1.0 }
        }
        
        // Start individual pulsing animations while dots are visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            startDotPulsingAnimations()
        }
        
    }
    
    private func startDotPulsingAnimations() {
        // Create individual timers for each dot pulsing animation
        let animationSpeed = 1.2
        for index in 0..<numberOfDots {
            Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
                if index < animationPhases.count {
                    animationPhases[index] += 0.1 / animationSpeed
                    if animationPhases[index] > Double.pi * 2 {
                        animationPhases[index] -= Double.pi * 2
                    }
                }
                
                // Stop the timer when dots start disappearing
                if dotScales[index] < 0.5 {
                    timer.invalidate()
                }
            }
        }
    }
}
