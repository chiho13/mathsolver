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

      
    // State variables for alert handling
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
        VStack {
            // App Icon
//            GeometryReader { geometry in
//               ZStack(alignment: .leading) {
//                   // Background bar
//                   Capsule()
//                       .fill(Color.accentColor.lighten().opacity(0.5))
//                       .frame(height: 5)
//                   
//                   // Progress bar
//                   Capsule()
//                       .fill(LinearGradient(
//                                      gradient: Gradient(colors: [Color.accentColor, Color.teal]),
//                                      startPoint: .leading,
//                                      endPoint: .trailing
//                                  ))
//                       .frame(width: geometry.size.width * (CGFloat(currentIndex + 1) / CGFloat(pages.count)), height: 5)
//                       .animation(.easeInOut(duration: 0.2), value: currentIndex)
//               }
//           }
//           .frame(height: 4)
//           .padding(.horizontal, 20)
//           .padding(.top, 10)
//           .padding(.bottom, 20)
            
//            if !isSmallScreen {
//                Image("icon100")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 80, height: 80)
//                    .cornerRadius(24)
//                    .padding(.top, 40)
//            }
            // Welcome Message
//            VStack {
//                Text("Ekto Live Interpreter")
//            }
//            .font(.system(size: 32, weight: .bold))
//            .foregroundColor(.primary)
//            .fontWeight(.bold)
//            .padding(.top, 20)

//             VStack {
//                Text("translated captions for lectures, talks and speeches")
//                        .multilineTextAlignment(.center)
//            }
//             .font(.system(size: 22, weight: .semibold))
//            .foregroundColor(.accentColor)
            
//            Text("see and understand anyone with translated captions")
//                .font(.system(size: 22, weight: .bold))
//                .foregroundColor(.accentColor)
//                .overlay(
//                    LinearGradient(
//                        gradient: colorScheme == .light ? Gradient(colors: [
//                            Color.fromHex("#2a7ae3"),
//                            Color.fromHex("#1643d4")
//                        ]) : Gradient(colors: [
//                            .teal,
//                            Color.fromHex("#2a7ae3")
//                        ]),
//                        startPoint: .leading,
//                        endPoint: .trailing
//                    )
//                    .mask(
//                        Text("see and understand anyone with translated caption")
//                            .font(.system(size: 22, weight: .bold))
//                    )
//                )
//                .lineLimit(3)
//                .multilineTextAlignment(.leading)
//            
//            .padding(.top, 20)
//            .padding(.horizontal, 20)


            // Carousel for Bullet Points
            TabView(selection: $currentIndex) {
                ForEach(0..<pages.count, id: \.self) { pageIndex in
                    VStack(alignment: .leading) {
                        
                        HStack {
                            Spacer()
                            
                            VStack {
                                if pageIndex == 2 { // Language Selection Page
                                    
                                    
//                                    VStack(spacing: 32) {
//                                        Spacer()
//                                        HStack {
//                                            Spacer()
//                                            VStack(spacing: 16) {
//                                                
//                                                Image(systemName: "globe")
//                                                    .font(.system(size: 40))
//                                                    .foregroundColor(colorScheme == .dark ? Color.fromHex("#f7cbe3") : .accentColor)
//                                                    .frame(width: 40, alignment: .leading)
//                                                
//                                                Text("Choose language pairs")
//                                                    .font(.system(size: 20))
//                                                    .italic()
//                                                    .fontWeight(.bold)
//                                                    .padding(.top, 30)
//                                                    .padding(.bottom, 22)
//                                                    .padding(.horizontal, 24)
//                                                
//                                            }
//                                            Spacer()
//                                        }.padding(.top, 24)
//                                        
//                                        
//                                        Text("Their Language")
//                                            .font(.system(size: 20, weight: .semibold))
//                                            .foregroundColor(.primary.opacity(0.9))
//                                            .padding(.bottom, 4)
//                                        
//                                       
//                                        
//                                        Spacer()
//                                    }
//                                    .padding(.horizontal, 24)
                                    
                                    
                                }
                            }
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading) {
                            Spacer()
                            ForEach(pages[pageIndex].indices, id: \.self) { index in
                                let bulletPoint = pages[pageIndex][index]
                                HStack {
                                    Spacer()
                                    VStack(spacing: 16) {
                                        if pageIndex < 2 && index == 0 {
                                            //                Image(systemName: bulletPoint.iconName)
                                            //                    .font(.system(size: 40))
                                            //                    .foregroundColor(.accentColor)
                                            //                    .frame(width: 40, alignment: .leading)
                                            
                                            let localizedString = NSLocalizedString(bulletPoint.text, comment: "")
                                            let processedString = localizedString.replacingOccurrences(of: "\\n", with: "\n")
                                            
                                            Text(processedString)
                                                .multilineTextAlignment(.leading)
                                                .font(.system(size: 22))
                                                .fontWeight(.bold)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.top, 40)
                                                .padding(.bottom, 22)
                                                .padding(.horizontal, 24)
                                        }
                                    }
                                    Spacer()
                                }
                                
                                if index != 0 {
                                    HStack(spacing: 16) {
                                        Image(systemName: bulletPoint.iconName)
                                            .font(.system(size: 22))
                                            .foregroundColor(colorScheme == .dark ? Color.fromHex("#f7cbe3") : .accentColor)
                                            .frame(width: 40, alignment: .leading)
                                        
                                        Text(LocalizedStringKey(bulletPoint.text))
                                        
                                            .font(.system(size: 16)).padding(.leading, 4)
                                    }
                                    .padding(.horizontal, 40)
                                    .padding(.top, 20)
                                }
                            }
                            Spacer()
                        }
                        
                        // Show "Allow Microphone Access" button on the last page
                        
                        //                        if pageIndex == pages.count - 1 {
                        //                            VStack(spacing: 16) {
                        //                                Text("To enable real-time translation, we need access to your microphone.")
                        //                                    .font(.system(size: 20))
                        //                                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        //                                    .multilineTextAlignment(.center)
                        //                                    .padding(.horizontal, 24)
                        //                            }
                        //                            .padding(.vertical, 20)
                        //                        }
                        
                        
                        Spacer()
                        
                        if pageIndex < 2 {
                            
                            GeometryReader { geometry in
                                  Image("onboardingPage\(pageIndex+1)")
                                      .resizable()
                                      .scaledToFit()
                                      // Set image width to 80% of the container's width
                                      .frame(width: geometry.size.width * 0.85)
                                      .padding(.bottom, 30)
                                      .padding(.horizontal, 20)
                                      // Center the image within the available width
                                      .frame(width: geometry.size.width, alignment: .center)
                              }
                              
                            
                        }
                    }
                    .tag(pageIndex)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) 

            Spacer()

            // Custom Page Indicator
             HStack(spacing: 8) {
                 ForEach(0..<pages.count, id: \.self) { index in
                     Circle()
                         .fill(index == currentIndex ? Color.accentColor : Color.gray.opacity(0.5))
                         .frame(width: 10, height: 10)
                         .animation(.easeInOut(duration: 0.2), value: currentIndex)
                 }
             }
             .padding(.top, 10)
             .padding(.bottom, 20) 
           

            // "Next" Button
            if currentIndex < pages.count - 1 {
                NextButton(currentIndex: $currentIndex, totalPages: pages.count)
            } else {
                
                ContinueButton(isFirstLaunch: $isFirstLaunch)
//                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
           
        }
        .offset(x: viewOffset) // Apply the offset to the entire view
        .animation(.easeInOut(duration: 0.3), value: viewOffset) // Animate the offset change
       .background(
                    colorScheme == .dark ? 
                        LinearGradient(
                            gradient: Gradient(colors: [Color.fromHex("#540e30").opacity(0.2), Color.fromHex("#1d031f")]),
                            startPoint: .top,
                            endPoint: .bottom
                        ) : LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
        .alert(isPresented: $showSettingsAlert) {
            Alert(
                title: Text("Microphone Access Needed"),
                message: Text("To enable real-time translation, we need access to your microphone. Please enable microphone access in Settings to use this feature."),
                primaryButton: .default(Text("Open Settings")) {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: - Subviews
  func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            // For SwiftUI versions supporting @Environment
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #endif
        }
    }
    
    private func continueNext() {
        withAnimation {
        viewOffset = -UIScreen.main.bounds.width // Slide the view to the left
    }
    
    if iapManager.isPremium {
        showPremView = false
    } else {
        showPremView = true
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        withAnimation {
            $isFirstLaunch.wrappedValue = false
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    }
    /// "Continue" button that appears on the last page after microphone access is granted
    @ViewBuilder
    private func ContinueButton(isFirstLaunch: Binding<Bool>) -> some View {
        Button(action: {
            
            Task {
//                await requestMicrophonePermission()
                
                withAnimation {
                    viewOffset = -UIScreen.main.bounds.width // Slide the view to the left
                }
                
                if iapManager.isPremium {
                    showPremView = false
                } else {
                    showPremView = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        isFirstLaunch.wrappedValue = false
                        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                    }
                }
            }
        }) {
            HStack {
                Spacer()
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()

            // .background(
            //     LinearGradient(gradient: Gradient(colors: [Color.fromHex("#2a7ae3"), Color.fromHex("#1643d4")]), startPoint: .top, endPoint: .bottom)
            // )
            .cornerRadius(10)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.horizontal, 20)
        .padding(.bottom, 20) 
    }


    /// "Next" button for navigating through onboarding pages
    @ViewBuilder
    private func NextButton(currentIndex: Binding<Int>, totalPages: Int) -> some View {
        Button(action: {
            withAnimation {
                currentIndex.wrappedValue += 1
            }
        }) {
            HStack {
                Spacer()
                Text(self.currentIndex == 0 ? "get-started": "next")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            // .background(
            //     LinearGradient(gradient: Gradient(colors: [Color.fromHex("#2a7ae3"), Color.fromHex("#1643d4")]), startPoint: .top, endPoint: .bottom)
            // )
            .cornerRadius(10)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.horizontal, 20)
        .padding(.bottom, 20) 
    }

    // MARK: - Permission Handling

    private let pages: [[BulletPoint]] = [
        // Page 1: Core benefits
        [
            // Use localized keys that match your JSON file
            BulletPoint(iconName: "star.fill", text: "onboarding-page1"),
            BulletPoint(iconName: "mic.fill", text: "onboarding-page1-bulletpointone"),
            BulletPoint(iconName: "person.wave.2", text: "onboarding-page1-bulletpointtwo")
        ],
        // Page 2: Live event benefits
        [
            BulletPoint(iconName: "bubble.left.and.bubble.right.fill", text: "onboarding-page2"),
            BulletPoint(iconName: "person.2.fill", text: "onboarding-page2-bulletpointtwo"),
//            BulletPoint(iconName: "briefcase.fill", text: "onboarding-page2-bulletpointone"),
        ],
        // Page 3: Education & language learning
//        [
//            BulletPoint(iconName: "arrow.left.arrow.right.circle.fill", text: "onboarding-page3"),
//            BulletPoint(iconName: "bubble.left.and.bubble.right.fill", text: "onboarding-page3-bulletpointone"),
//            BulletPoint(iconName: "person.2.fill", text: "onboarding-page3-bulletpointtwo")
//        ],
        // Page 4: Personalization (Language Selection)
//        [
//            BulletPoint(iconName: "globe", text: "Choose language pairs")
//        ]
    ]


    
    private func requestMicrophonePermission() async {
        let permission = AVAudioApplication.shared.recordPermission
        print("Current microphone permission: \(permission.rawValue)")
       

        switch permission {
        case .granted:
            print("Microphone permission already granted.")
            await MainActor.run {
                isMicrophonePermissionGranted = true
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                    continueNext()
//                }
                // Animate the "Continue" button appearance
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
                    // Animate the "Continue" button appearance
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                        continueNext()
//                    }
                                                  
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

    /// Struct to represent a bullet point
    private struct BulletPoint: Hashable {
        let iconName: String
        let text: String
    }

    /// Helper to retrieve app icon if needed
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


//[Color.fromHex("#2a7ae3"), Color.fromHex("#1643d4")]
