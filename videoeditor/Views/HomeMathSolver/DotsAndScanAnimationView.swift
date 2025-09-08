import SwiftUI

struct DotsAndScanAnimationView: View {
    let captureRect: CGRect
    let isAnimating: Bool
    @State private var dotPositions: [CGPoint] = []
    @State private var dotScales: [CGFloat] = []
    @State private var animationPhases: [Double] = []
    @State private var waveDriver: Double = 0.0
    @State private var scanLineOffset: CGFloat = 0
    @State private var scanLineOpacity: Double = 1.0
    @State private var showScanLine: Bool = true
    @State private var showDots: Bool = false
    @State private var numberOfDots: Int = 12
    private let dotDensity: CGFloat = 0.00025
    private let dotSize: CGFloat = 5.0
    private let scanLineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            if showScanLine {
                Rectangle()
                    .fill(Color.fromHex("#00e17b"))
                    .opacity(scanLineOpacity)
                    .frame(width: scanLineWidth, height: captureRect.height)
                    .position(
                        x: captureRect.origin.x + scanLineOffset,
                        y: captureRect.origin.y + captureRect.height / 2
                    )
            }
            if showDots {
                ForEach(0..<numberOfDots, id: \.self) { index in
                    if index < dotPositions.count {
                        Circle()
                            .fill(Color.white)
                            .frame(width: dotSize, height: dotSize)
                            .opacity(0.9)
                            .scaleEffect(dotScales[index] * (1.0 + 0.3 * abs(sin(animationPhases[index]))))
                            .position(dotPositions[index])
                            .animation(.none, value: dotPositions[index])
                    }
                }
            }
        }
        .onAppear {
            recalculateDotCount()
            if isAnimating { startScanLineAnimation() }
        }
        .onChange(of: captureRect) { _, _ in
            recalculateDotCount()
            if isAnimating { resetAnimation() }
        }
        .onChange(of: isAnimating) { _, anim in
            if anim {
                resetAnimation()
            } else {
                withAnimation(.easeIn(duration: 0.3)) {
                    dotScales = Array(repeating: 0.0, count: numberOfDots)
                }
            }
        }
    }

    private func recalculateDotCount() {
        let area = captureRect.width * captureRect.height
        let calculatedDots = max(16, Int(area * dotDensity))
        numberOfDots = min(calculatedDots, 50)
    }

    private func generateRandomPositions() {
        let minHeightForPadding: CGFloat = 60.0
        let basePadding: CGFloat = 5.0
        let additionalPaddingFactor: CGFloat = 0.1
        let heightAboveMin = max(0, captureRect.height - minHeightForPadding)
        var calculatedPadding = basePadding + (heightAboveMin * additionalPaddingFactor)
        let maxAllowedPadding = min(captureRect.width, captureRect.height) / 3.0
        calculatedPadding = min(calculatedPadding, maxAllowedPadding)
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
        var newPositions: [CGPoint] = []
        var attempts = 0
        let area = usableRect.width * usableRect.height
        let defaultHeight: CGFloat = 120.0
        let heightFactor = min(1.0, captureRect.height / defaultHeight)
        let spacingModifier = (heightFactor * 0.4) + 0.6
        let minSpacing = sqrt(area / CGFloat(numberOfDots)) * 0.7 * spacingModifier
        let maxAttempts = numberOfDots * 100
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
        dotPositions = newPositions
        animationPhases = (0..<numberOfDots).map { _ in Double.random(in: 0...Double.pi * 2) }
    }

    private func startScanLineAnimation() {
        showScanLine = true
        showDots = false
        scanLineOffset = -scanLineWidth / 2
        scanLineOpacity = 1.0
        generateRandomPositions()
        withAnimation(.linear(duration: 0.4)) {
            scanLineOffset = captureRect.width + scanLineWidth / 2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showScanLine = false
            showDots = true
            startDotLifecycleAnimation()
        }
    }

    private func resetAnimation() {
        showScanLine = true
        showDots = false
        scanLineOffset = -scanLineWidth / 2
        scanLineOpacity = 1.0
        dotScales = Array(repeating: 0.0, count: numberOfDots)
        startScanLineAnimation()
    }

    private func startDotLifecycleAnimation() {
        generateRandomPositions()
        dotScales = Array(repeating: 0.0, count: numberOfDots)
        withAnimation(.easeOut(duration: 0.3)) {
            dotScales = (0..<numberOfDots).map { _ in 1.0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            startDotPulsingAnimations()
        }
    }

    private func startDotPulsingAnimations() {
        let animationSpeed = 1.2
        for index in 0..<numberOfDots {
            Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
                if index < animationPhases.count {
                    animationPhases[index] += 0.1 / animationSpeed
                    if animationPhases[index] > Double.pi * 2 {
                        animationPhases[index] -= Double.pi * 2
                    }
                }
                if dotScales[index] < 0.5 {
                    timer.invalidate()
                }
            }
        }
    }
}
