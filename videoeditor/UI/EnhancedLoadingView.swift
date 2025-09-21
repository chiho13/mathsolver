//
//  EnhancedLoadingView.swift
//  videoeditor
//
//  Created by Assistant on 21/09/2025.
//

import SwiftUI

struct EnhancedLoadingView: View {
    let title: String
    let subtitle: String?
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Enhanced loading spinner
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 64, height: 64)
                
                // Animated arc
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: rotationAngle)
                
                // Center pulse dot
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseScale)
            }
            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, 32)
        .onAppear {
            rotationAngle = 360
            pulseScale = 1.3
        }
    }
}

// Math-specific loading view
struct MathSolvingLoadingView: View {
    @State private var currentStep = 0
    private let steps = [
        "Reading equation...",
        "Analyzing problem...",
        "Calculating solution...",
        "Preparing steps..."
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            EnhancedLoadingView(
                title: "Solving your math problem",
                subtitle: "This may take a few seconds"
            )
            
            // Step indicator
            VStack(spacing: 12) {
                Text(steps[currentStep])
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .scaleEffect(index == currentStep ? 1.2 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
                    }
                }
            }
        }
        .onAppear {
            startStepAnimation()
        }
    }
    
    private func startStepAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = (currentStep + 1) % steps.count
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        EnhancedLoadingView(
            title: "Loading...",
            subtitle: "Please wait a moment"
        )
        
        MathSolvingLoadingView()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
}
