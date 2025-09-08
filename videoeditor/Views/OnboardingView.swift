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
                    // RoundedRectangle(cornerRadius: 4)
                    //     .fill(Color.gray.opacity(0.15))
                    //     .frame(height: 8)
                    
                    // // Progress bar
                    // RoundedRectangle(cornerRadius: 4)
                    //     .fill(LinearGradient(
                    //         gradient: Gradient(colors: [
                    //             colorScheme == .dark ? Color.fromHex("#f7cbe3") : Color.accentColor,
                    //             colorScheme == .dark ? Color.fromHex("#f7cbe3").opacity(0.7) : Color.accentColor.opacity(0.8)
                    //         ]),
                    //         startPoint: .leading,
                    //         endPoint: .trailing
                    //     ))
                    //     .frame(width: geometry.size.width * (CGFloat(currentIndex + 1) / CGFloat(pages.count)), height: 8)
                    //     .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentIndex)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 40)

            // Main content
            TabView(selection: $currentIndex) {
                ForEach(0..<pages.count, id: \.self) { pageIndex in
                    VStack(spacing: 0) {
                        // Content area
                        VStack(alignment: .center, spacing: 40) {
                            // Title section
                            VStack(spacing: 28) {
                                ForEach(pages[pageIndex].indices, id: \.self) { index in
                                    let bulletPoint = pages[pageIndex][index]
                                    
                                    if index == 0 {
                                        // Main title
                                        VStack(spacing: 24) {
                                            // Enhanced icon with background
                                            ZStack {
                                                Circle()
                                                    .fill(LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            (colorScheme == .dark ? Color.fromHex("#f7cbe3") : Color.accentColor).opacity(0.15),
                                                            (colorScheme == .dark ? Color.fromHex("#f7cbe3") : Color.accentColor).opacity(0.05)
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ))
                                                    .frame(width: 100, height: 100)
                                                
                                                Image(systemName: bulletPoint.iconName)
                                                    .font(.system(size: 44, weight: .medium))
                                                    .foregroundColor(colorScheme == .dark ? Color.fromHex("#f7cbe3") : .accentColor)
                                            }
                                            .shadow(color: (colorScheme == .dark ? Color.fromHex("#f7cbe3") : Color.accentColor).opacity(0.2), radius: 20, x: 0, y: 10)
                                            
                                            let localizedString = NSLocalizedString(bulletPoint.text, comment: "")
                                            let processedString = localizedString.replacingOccurrences(of: "\\n", with: "\n")
                                            
                                            Text(processedString)
                                                .multilineTextAlignment(.center)
                                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                                .foregroundStyle(LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        .primary,
                                                        .primary.opacity(0.8)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ))
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.horizontal, 20)
                                                .lineSpacing(4)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 20)
                            
                            // Feature list
                            VStack(spacing: 24) {
                                ForEach(pages[pageIndex].indices, id: \.self) { index in
                                    let bulletPoint = pages[pageIndex][index]
                                    
                                    if index != 0 {
                                        HStack(spacing: 20) {
                                            // Enhanced icon container
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .fill(LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            (colorScheme == .dark ? Color.fromHex("#f7cbe3") : Color.accentColor).opacity(0.15),
                                                            (colorScheme == .dark ? Color.fromHex("#f7cbe3") : Color.accentColor).opacity(0.08)
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ))
                                                    .frame(width: 52, height: 52)
                                                
                                                Image(systemName: bulletPoint.iconName)
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundColor(colorScheme == .dark ? Color.fromHex("#f7cbe3") : .accentColor)
                                            }
                                            .shadow(color: (colorScheme == .dark ? Color.fromHex("#f7cbe3") : Color.accentColor).opacity(0.15), radius: 8, x: 0, y: 4)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(LocalizedStringKey(bulletPoint.text))
                                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                    .foregroundColor(.primary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .multilineTextAlignment(.leading)
                                                    .lineSpacing(2)
                                            }
                                            
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 28)
                                        .padding(.vertical, 8)
                                        // .background(
                                        //     RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        //         .fill(Color.primary.opacity(0.02))
                                        //         .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                                        // )
                                        .padding(.horizontal, 8)
                                        .opacity(index == 0 ? 0 : 1)
                                        .scaleEffect(index == 0 ? 0.9 : 1.0)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.15), value: currentIndex)
                                    }
                                }
                            }
                            .padding(.top, 20)
                            
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
            
            // Enhanced page indicator
            HStack(spacing: 16) {
                ForEach(0..<pages.count, id: \.self) { index in
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.25))
                            .frame(width: 10, height: 10)
                        
                        // Active indicator
                        if index == currentIndex {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [
                                        colorScheme == .dark ? Color.fromHex("#f7cbe3") : Color.accentColor,
                                        colorScheme == .dark ? Color.fromHex("#f7cbe3").opacity(0.8) : Color.accentColor.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 12, height: 12)
                                .shadow(color: (colorScheme == .dark ? Color.fromHex("#f7cbe3") : Color.accentColor).opacity(0.4), radius: 4, x: 0, y: 2)
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentIndex)
                }
            }
            .padding(.vertical, 32)
            
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
                        Color.fromHex("#540e30").opacity(0.12),
                        Color.fromHex("#1d031f").opacity(0.6),
                        Color.black.opacity(0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor.opacity(0.03),
                        Color.clear,
                        Color.gray.opacity(0.02)
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
                Text(self.currentIndex == 0 ? "Get Started" : "Continue")
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
            BulletPoint(iconName: "function", text: "onboarding-page1"),
            BulletPoint(iconName: "camera.fill", text: "onboarding-page1-bulletpointone"),
            BulletPoint(iconName: "x.squareroot", text: "onboarding-page1-bulletpointtwo")
        ],
        [
            BulletPoint(iconName: "lightbulb.fill", text: "onboarding-page2"),
            BulletPoint(iconName: "list.number", text: "onboarding-page2-bulletpointtwo"),
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
