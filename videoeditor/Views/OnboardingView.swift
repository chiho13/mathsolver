//
//  OnboardingView.swift
//  videoeditor
//
//  Created by Anthony Ho on 18/06/2025.
//

import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @Binding var isFirstLaunch: Bool
    @Binding var showPremView: Bool
    
    @State private var showPremiumView = false
    @State private var currentIndex = 0
    @State private var showPermissionDeniedAlert = false
    @State private var showPermissionRestrictedAlert = false
    @State private var showPermissionGrantedAlert = false
    @State private var showAudioSetupErrorAlert = false
    @State private var showSettingsAlert = false
    @State private var isMicrophonePermissionGranted = false
    @State private var viewOffset: CGFloat = 0
    
    @EnvironmentObject var iapManager: IAPManager 
    @Environment(\.colorScheme) var colorScheme
    
    var isSmallScreen: Bool {
        UIScreen.main.bounds.height <= 667 // iPhone SE height
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.25))
                        .frame(height: 6)
                    
                    // Progress bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * (CGFloat(currentIndex + 1) / CGFloat(pages.count)), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 70)
            .opacity(0)

            // Main content
            TabView(selection: $currentIndex) {
                ForEach(0..<pages.count, id: \.self) { pageIndex in
                    VStack(spacing: 0) {
                        // Content area
                        VStack(alignment: .center, spacing: 32) {
                            // Title section
                            VStack(spacing: 24) {
                                ForEach(pages[pageIndex].indices, id: \.self) { index in
                                    let bulletPoint = pages[pageIndex][index]
                                    
                                    if index == 0 {
                                        // Main title
                                        VStack(spacing: 20) {
                                            Image(systemName: bulletPoint.iconName)
                                                .font(.system(size: 48, weight: .medium))
                                                .foregroundColor(colorScheme == .dark ? Color.fromHex("#f7cbe3") : .accentColor)
                                                .padding(.bottom, 4)
                                            
                                            let localizedString = NSLocalizedString(bulletPoint.text, comment: "")
                                            let processedString = localizedString.replacingOccurrences(of: "\\n", with: "\n")
                                            
                                            Text(processedString)
                                                .multilineTextAlignment(.center)
                                                .font(.system(size: 26, weight: .bold))
                                                .foregroundColor(.primary)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.horizontal, 24)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 32)
                            
                            // Feature list
                            VStack(spacing: 28) {
                                ForEach(pages[pageIndex].indices, id: \.self) { index in
                                    let bulletPoint = pages[pageIndex][index]
                                    
                                    if index != 0 {
                                        HStack(spacing: 18) {
                                            // Icon container
                                            ZStack {
                                                Circle()
                                                    .fill(Color.accentColor.opacity(0.12))
                                                    .frame(width: 44, height: 44)
                                                
                                                Image(systemName: bulletPoint.iconName)
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(colorScheme == .dark ? Color.fromHex("#f7cbe3") : .accentColor)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(LocalizedStringKey(bulletPoint.text))
                                                    .font(.system(size: 17, weight: .medium))
                                                    .foregroundColor(.primary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 36)
                                        .opacity(index == 0 ? 0 : 1)
                                        .animation(.easeInOut(duration: 0.5).delay(Double(index) * 0.1), value: currentIndex)
                                    }
                                }
                            }
                            .padding(.top, 40)
                            
                            Spacer()
                        }
                        
                        // Image section
                        if pageIndex < 2 {
                            VStack {
                                Spacer()
                                Image("onboardingPage\(pageIndex+1)")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 32)
                                    .padding(.bottom, 32)
                                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                                Spacer()
                            }
                        }
                    }
                    .tag(pageIndex)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Page indicator
            HStack(spacing: 12) {
                ForEach(0..<pages.count, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: index == currentIndex ? 10 : 8, height: index == currentIndex ? 10 : 8)
                            .opacity(index == currentIndex ? 1 : 0)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentIndex)
                }
            }
            .padding(.vertical, 24)
            
            // Action buttons
            VStack(spacing: 16) {
                if currentIndex < pages.count - 1 {
                    NextButton(currentIndex: $currentIndex, totalPages: pages.count)
                } else {
                    ContinueButton(isFirstLaunch: $isFirstLaunch)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .offset(x: viewOffset)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewOffset)
        .background(
            colorScheme == .dark ?
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.fromHex("#540e30").opacity(0.15),
                        Color.fromHex("#1d031f").opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor.opacity(0.02),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
        )
    }

    // MARK: - Subviews
    
    private func continueNext() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            viewOffset = -UIScreen.main.bounds.width
        }
        
        if iapManager.isPremium {
            showPremView = false
        } else {
            showPremView = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                $isFirstLaunch.wrappedValue = false
                UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            }
        }
    }
    
    @ViewBuilder
    private func ContinueButton(isFirstLaunch: Binding<Bool>) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewOffset = -UIScreen.main.bounds.width
            }
            
            if iapManager.isPremium {
                showPremView = false
            } else {
                showPremView = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    isFirstLaunch.wrappedValue = false
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                }
            }
        }) {
            HStack(spacing: 12) {
                Spacer()
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor,
                        Color.accentColor.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }

    @ViewBuilder
    private func NextButton(currentIndex: Binding<Int>, totalPages: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentIndex.wrappedValue += 1
            }
        }) {
            HStack(spacing: 12) {
                Spacer()
                Text(self.currentIndex == 0 ? "Get Started" : "Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor,
                        Color.accentColor.opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Data

    private let pages: [[BulletPoint]] = [
        [
            BulletPoint(iconName: "doc.text.fill", text: "onboarding-page1"),
            BulletPoint(iconName: "square.grid.2x2.fill", text: "onboarding-page1-bulletpointone"),
            BulletPoint(iconName: "arrow.clockwise.circle.fill", text: "onboarding-page1-bulletpointtwo")
        ],
        [
            BulletPoint(iconName: "square.and.arrow.up.fill", text: "onboarding-page2"),
            BulletPoint(iconName: "icloud.and.arrow.up.fill", text: "onboarding-page2-bulletpointtwo"),
        ]
    ]

    // MARK: - Permission Handling
    
    private func requestMicrophonePermission() async {
        let permission = AVAudioApplication.shared.recordPermission
        print("Current microphone permission: \(permission.rawValue)")
       
        switch permission {
        case .granted:
            print("Microphone permission already granted.")
            await MainActor.run {
                isMicrophonePermissionGranted = true
                withAnimation {
                    // Any additional state updates if needed
                }
            }
        case .denied:
            await MainActor.run {
                showSettingsAlert = true
            }
            print("Microphone permission denied.")
        case .undetermined:
            print("Microphone permission undetermined. Requesting permission...")
            let granted = await requestPermission()
            await MainActor.run {
                if granted {
                    print("Microphone permission granted.")
                    isMicrophonePermissionGranted = true
                    withAnimation {
                        // Any additional state updates if needed
                    }
                } else {
                    print("Microphone permission denied by user.")
                    showSettingsAlert = true
                }
            }
        @unknown default:
            print("Microphone permission state is unknown or restricted.")
            await MainActor.run {
                showPermissionRestrictedAlert = true
            }
        }
    }

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                print("Permission request completed. Granted: \(granted)")
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Supporting Structures

    private struct BulletPoint: Hashable {
        let iconName: String
        let text: String
    }

    private func getAppIcon() -> UIImage? {
        if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIconDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIconDictionary["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}

// MARK: - Custom Button Style

