//
//  BubbleBackgroundPayWallView.swift
//  videoeditor
//
//  Created by Anthony Ho on 19/06/2025.
//


////
////  PremiumView.swift
////  all ears
////
////  Created by Anthony Ho on 16/01/2025.
////

import Foundation
import SwiftUI

struct BubbleBackgroundPayWallView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.fromHex("#4430f2").opacity(0.12))
                    .frame(width: geo.size.width * 0.45,
                           height: geo.size.width * 0.45)
                    .offset(x: -geo.size.width * 0.2,
                            y: -geo.size.width * 0.2)
                
                Circle()
                    .fill(Color.fromHex("#4430f2").opacity(0.1))
                    .frame(width: geo.size.width * 0.3,
                           height: geo.size.width * 0.3)
                    .offset(x: geo.size.width * 0.7,
                            y: 0)
                
                
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: geo.size.width * 0.2,
                           height: geo.size.width * 0.2)
                     .offset(x: -geo.size.width * 0.2,
                              y: geo.size.height * 0.1)
                
                
                Circle()
                    .fill(Color.fromHex("#4430f2").opacity(0.13))
                    .frame(width: geo.size.width * 0.3,
                           height: geo.size.width * 0.3)
                     .offset(x: -geo.size.width * 0.15,
                              y: geo.size.height * 0.6)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.09))
                    .frame(width: geo.size.width * 0.4,
                           height: geo.size.width * 0.4)
                    .offset(x: geo.size.width * 0.7,
                            y:  geo.size.height * 0.7)

            }
        }
    }
}



struct LegacyPremiumView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var iapManager: IAPManager // Access IAPManager from the environment
    @Environment(\.openURL) var openURL // Environment variable to handle URL opening
    
    var headline: String
    // State variables
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isPurchasing: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    var isSmallScreen: Bool {
        UIScreen.main.bounds.height <= 667 // iPhone SE height
    }

    @State private var activeAlert: ActiveAlert?

 @State private var showCloseButton: Bool = false
    /// For controlling opacity of the close button (fade in).
    @State private var closeButtonOpacity: Double = 0.0

    @State private var progress: Double = 0.0 // Add a state variable for progress


  enum ActiveAlert: Identifiable {
    case success
    case error

    var id: Int {
        switch self {
        case .success: return 1
        case .error: return 2
        }
    }
}

    

    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // Background Gradient
                BubbleBackgroundPayWallView()
                
                // Add dark mode gradient background
                // if colorScheme == .dark {
                //     LinearGradient(
                //         gradient: Gradient(colors: [Color.black, Color.fromHex("#020d19")]),
                //         startPoint: .top,
                //         endPoint: .bottom
                //     )
                //     .ignoresSafeArea()
                // }
                
                    VStack(spacing: 20) {
                        TopSectionView(selectedPlan: $selectedPlan, isSmallScreen: isSmallScreen, headline: headline)
                        
                        BottomSectionView(
                            isSmallScreen: isSmallScreen,
                            selectedPlan: $selectedPlan,
                            iapManager: iapManager,
                            purchaseAction: purchaseSelectedPlan,
                            restoreAction: restorePurchases,
                            colorScheme: colorScheme,
                            isPurchasing: isPurchasing
                        )
                        .padding(.top, 10)
                        .padding(.horizontal, 6)
                    }
                    .padding(.bottom, isSmallScreen ? 20 : 0) // Add padding for small screens
                    
                
                
                
                // Close Button
                VStack {
                    HStack {
                     
                        Spacer()
                        CloseButton(action: {
                            dismiss()
                        })
                        .transition(.opacity) // Fade transition
//                        .opacity(closeButtonOpacity)
                        
                    }
                    Spacer() // Pushes the button to the top
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure the overlay covers the entire screen
                
                
                
                if isPurchasing {
                    // Nested ZStack for centering
                    ZStack {
                        // Semi-transparent background to dim the underlying content
                        //                              Color.gray.opacity(0.4)
                        //                                  .ignoresSafeArea()
                        //                                  .transition(.opacity)
                        
                        // Centered Spinner using ActivityIndicator
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5) // Optional: Adjust size
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.8))
                            .cornerRadius(10)
                            .accessibility(label: Text("Processing your purchase"))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure the overlay covers the entire screen
                    .animation(.easeInOut, value: isPurchasing) // Animate the overlay's appearance
                }
                
            }
            // Alerts
            .onAppear {
                // Wait 2 seconds, then animate the button in.
                
                // Replace CircularProgressView with CloseButton after the progress animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeIn(duration: 1.0)) {
                        closeButtonOpacity = 1.0
                    }
                }
            }
            .alert(item: $activeAlert) { alertType in
                switch alertType {
                case .success:
                    return Alert(
                        title: Text("Success"),
                        message: Text("You're all set! Purchase successful!"),
                        dismissButton: .default(Text("OK"), action: {
                            dismiss() // Dismiss the view on success
                        })
                    )
                case .error:
                    return Alert(
                        title: Text("Error"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
                
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
        .background(
                    colorScheme == .dark ? 
                        LinearGradient(
                            gradient: Gradient(colors: [Color.fromHex("#540e30").opacity(0.2), Color.fromHex("#29022b").opacity(0.5)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ) : LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
    }

   private func purchaseSelectedPlan() async {
    isPurchasing = true
    let success = await iapManager.purchase(plan: selectedPlan)
    isPurchasing = false
    if success {
        activeAlert = .success
    } else {
        errorMessage = "There was an issue processing your purchase. Please try again."
        activeAlert = .error
    }
}

private func restorePurchases() async {
    isPurchasing = true
    await iapManager.restorePurchases()
    isPurchasing = false
    if iapManager.isPremium {
        activeAlert = .success
    } else {
        errorMessage = "No purchases were found to restore."
        activeAlert = .error
    }
}
}
//
//struct BackgroundGradient: View {
//    @Environment(\.colorScheme) var colorScheme // Access the color scheme
//
//    var body: some View {
//        Rectangle()
//            .fill(colorScheme == .dark ? Color.black : Color.white) // Use black for dark mode, white for light mode
//            .ignoresSafeArea()
//    }
//}
//
//struct TopSectionView: View {
//    let isSmallScreen: Bool
//    let geometry: GeometryProxy
//    
//    
//    var body: some View {
//        VStack(alignment: .center, spacing: 24) {
//            Image("icon100") // Use the app icon
//                .resizable()
//                .scaledToFit()
//                .frame(width: 100, height: 100)
//                .cornerRadius(24)
//            VStack(alignment: .leading, spacing: 24) { // Changed from VStack to HStack
//        
//                Text("See translated captions in real-time")
//                    .font(.system(size: isSmallScreen ? 24 : 32, weight: .bold))
//                    .foregroundColor(.accentColor)
//                   
//                
//                BenefitsView()
//                 
//            }
//            .padding(.horizontal, 20)
//
//        }
//        .padding(.top, 40)
//        
//    }
//
//      private func getAppIcon() -> UIImage? {
//        if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
//           let primaryIconDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
//           let iconFiles = primaryIconDictionary["CFBundleIconFiles"] as? [String],
//           let lastIcon = iconFiles.last {
//            return UIImage(named: lastIcon)
//        }
//        return nil
//    }
//}
//
//struct BenefitsView: View {
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            BenefitItem(text: "Unlimited Live Transcribe")
//            BenefitItem(text: "Unlimited AI Live Translations")
//            BenefitItem(text: "Unlimited saves to history")
//          
//        }
//        .padding(.top, 20)
//    }
//}
//
//struct BenefitItem: View {
//    let text: String
//
//    var body: some View {
//        HStack(spacing: 16) {
//             ZStack {
//        Circle()
//            .fill(Color.green.opacity(0.2)) // Light green background with opacity
//            .frame(width: 28, height: 28) // Ensure the circle is the same size as the checkmark
//
//        Image(systemName: "checkmark")
//            .font(.custom("SFProRoundedBold", size: 14))
//            .foregroundColor(.primary.opacity(0.7))
//        }
//                
//            Text(text)
//                .font(.custom("SFProRoundedSemibold", size: 18))
//                .foregroundColor(.primary)
//        }
//    }
//}
//
//struct BottomSectionView: View {
//    let isSmallScreen: Bool
//    let geometry: GeometryProxy
//    @Binding var selectedPlan: SubscriptionPlan
//    let iapManager: IAPManager
//    let purchaseAction: () async -> Void
//    let restoreAction: () async -> Void
//    let colorScheme: ColorScheme
//    let isPurchasing: Bool // Receive the purchasing state
//
//    var body: some View {
//        VStack(spacing: isSmallScreen ? 5 :  20) {
//            
//            VStack(spacing: 20) {
//                PlanSelectionRow(
//                    title: "Annual Plan",
//                     oldPrice: calculateOldPrice(from: iapManager.priceText(for: .weekly)),
//                    newPrice: "\(iapManager.priceText(for: .yearly)) per year",
//                    isSelected: selectedPlan == .yearly,
//                    onSelect: {
//                        withAnimation { selectedPlan = .yearly }
//                    }
//                )
//                
//                PlanSelectionRow(
//                    title: "Weekly Plan",
//                    oldPrice: nil,
//                    newPrice: "\(iapManager.priceText(for: .weekly)) per week",
//                    isSelected: selectedPlan == .weekly,
//                    onSelect: {
//                        withAnimation { selectedPlan = .weekly }
//                    }
//                )
//                
//            }.padding()
//            ContinueButton(action: purchaseAction, isDisabled: isPurchasing, selectedPlan: selectedPlan)
//            
//            HStack(spacing: 20) {
//            RestorePurchasesButton(action: restoreAction, isDisabled: isPurchasing)
//                       TermsButton(subscriptionInfoText: SubscriptionInfoText(selectedPlan: selectedPlan, iapManager: iapManager))
//            }
////            SubscriptionInfoText(selectedPlan: selectedPlan, iapManager: iapManager)
//
//            Spacer()
//        }
////        .background(
////            colorScheme == .light ? Color.white.opacity(0.9) : Color.black.opacity(0.8)
////        )
//        .cornerRadius(20, corners: [.topLeft, .topRight]) // Rounded top corners
//        .frame(
//            height: 300 + geometry.safeAreaInsets.bottom
//        ) // Allocate appropriate screen height
//        .ignoresSafeArea(edges: .bottom) // Cover safe area at the bottom
//    }
//
//    private func calculateOldPrice(from weeklyPriceText: String) -> String {
//    // Remove currency symbols and format the string to a number
//    let numberFormatter = NumberFormatter()
//    numberFormatter.numberStyle = .currency
//    numberFormatter.locale = Locale.current // Adjust locale if needed
//
//    // Convert the weekly price string to a number
//    if let weeklyPriceNumber = numberFormatter.number(from: weeklyPriceText) {
//        // Calculate the old price by multiplying by 52
//        let oldPriceNumber = weeklyPriceNumber.doubleValue * 52
//
//        // Format the old price back to a currency string
//        if let oldPriceText = numberFormatter.string(from: NSNumber(value: oldPriceNumber)) {
//            return oldPriceText
//        }
//    }
//
//    // Return a default value or handle error
//    return "N/A"
//}
//
//}
//
//
//struct PlanSelectionRow: View {
//    let title: String
//    let oldPrice: String?    // e.g. "£259.48"
//    let newPrice: String?    // e.g. "£24.99 per year"
//
//    let isSelected: Bool
//    let onSelect: () -> Void
//
//    var body: some View {
//        Button(action: onSelect) {
//            HStack {
//                // Text labels on the left
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    // Show old/new pricing or anything else you'd like
//                
//                // Show oldPrice + newPrice together if both exist
//if let oldPrice = oldPrice, let newPrice = newPrice {
//    HStack(spacing: 6) {
//        Text(oldPrice)
//            .strikethrough()
//            .foregroundColor(.gray)
//        Text(newPrice)
//            .foregroundColor(.primary)
//    }
//    .font(.subheadline)
//}
//// If there's no oldPrice, show only newPrice (if it exists)
//else if let newPrice = newPrice {
//    Text(newPrice)
//        .font(.subheadline)
//        .foregroundColor(.primary)
//}
//
//                }
//                
//                Spacer()
//                
//                // Optional discount badge
//
//                      if let discountText = calculateDiscountText(oldPrice: oldPrice, newPrice: newPrice) {
//                    Text(discountText)
//                         .font(.caption.bold())
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 8)
//                        .background(Color.red)
//                        .cornerRadius(4)
//                } 
////                else {
////                    Text("FREE TRIAL")
////                        .font(.headline)
////                        .foregroundColor(.white)
////                        .padding(.horizontal, 6)
////                        .padding(.vertical, 4)
////                }
//                
//                // Radio button on the far right
//                Circle()
//                    .stroke(isSelected ? Color.accentColor : Color.gray, lineWidth: 2)
//                    .fill(isSelected ? Color.accentColor : Color.clear)
//                    .frame(width: 24, height: 24)
//                    .overlay(
//                        Image(systemName: "checkmark")
//                                    .font(.system(size: 14))
//                                    .foregroundColor(.white)
//                                    .opacity(isSelected ? 1 : 0)
//                    )
//            }
//            .padding()
//            // Highlight background if selected
//             .background(
//                isSelected ? Color.accentColor.opacity(0.1) : Color.clear
//            )
//            // Always show a border, switching color if selected
//            .overlay(
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(isSelected ? Color.accentColor : Color.gray, lineWidth: 2)
//            )
//        }
//        .buttonStyle(.plain)
//    }
//
//     private func calculateDiscountText(oldPrice: String?, newPrice: String?) -> String? {
//        guard let oldPrice = oldPrice, let newPrice = newPrice,
//              let oldPriceValue = Double(oldPrice.filter("0123456789.".contains)),
//              let newPriceValue = Double(newPrice.filter("0123456789.".contains)) else {
//            return nil
//        }
//        
//        let discount = ((oldPriceValue - newPriceValue) / oldPriceValue) * 100
//        return String(format: "SAVE %.0f%%", discount)
//    }
//
//}
//
//
//struct ContinueButton: View {
//    let action: () async -> Void
//    let isDisabled: Bool
//    let selectedPlan: SubscriptionPlan // Pass in selectedPlan
//
//    var body: some View {
//        Button(action: {
//            Task { await action() }
//        }) {
//           
//                HStack {
//                    Spacer()
//                    Text("Continue") // Conditional text
//                         .font(.system(size: 18, weight: .semibold))
//                        .foregroundColor(.white)
//                    Image(systemName: "chevron.right") // Add chevron icon
//                        .font(.system(size: 18, weight: .semibold)) // Semi-bold chevron
//                        .foregroundColor(.white)
//                    Spacer()
//                }
//               
//            .frame(maxWidth: .infinity)
//            .padding()
////            .background(Color.accentColor)
//            .cornerRadius(10)
//        }
//        .buttonStyle(PressableButtonStyle())
//        .padding(.horizontal)
//        .disabled(isDisabled)
//        .opacity(isDisabled ? 0.6 : 1.0)
//    }
//}
//
//
//struct RestorePurchasesButton: View {
//    let action: () async -> Void
//    let isDisabled: Bool // Add this parameter
//
//    var body: some View {
//        Button(action: {
//            Task { await action() }
//        }) {
//            Text("Restore")
//                .font(.custom("SFProRoundedRegular", size: 14))
//                .foregroundColor(Color.gray)
//                .underline()
//                .padding(.top, 10)
//        }
//        .disabled(isDisabled) // Disable the button
//        .opacity(isDisabled ? 0.6 : 1.0) // Visual feedback
//    }
//}
//
//struct TermsButton: View {
//     @State private var showSubscriptionInfo: Bool = false
//    let subscriptionInfoText: SubscriptionInfoText // Accept the view
//
//    var body: some View {
//        Button(action: {
//            showSubscriptionInfo = true
//        }) {
//            Text("Terms of Service & Privacy Policy")
//                .font(.custom("SFProRoundedRegular", size: 14))
//                .foregroundColor(Color.gray)
//                .underline()
//                .padding(.top, 10)
//        }
//         .sheet(isPresented: $showSubscriptionInfo) {
//            VStack {
//                subscriptionInfoText // Present the SubscriptionInfoText view
//                Spacer() // Add a spacer to fill the remaining space
//            }
//            .frame(height: 150) // Set the height of the sheet content
//            .presentationDetents([.height(150)]) // Use a custom height detent
//        }
//    }
//}
//
//
//@MainActor
//struct SubscriptionInfoText: View {
//    let selectedPlan: SubscriptionPlan
//    let iapManager: IAPManager
//    @Environment(\.openURL) var openURL // Environment variable to handle URL opening
//
//    var body: some View {
//        VStack(alignment: .center, spacing: 0) {
//            if selectedPlan == .weekly {
//                subscriptionWeeklyAgreementText
//                    .padding(.horizontal, 20)
//                    .padding(.top, 10)
//            } else {
//                subscriptionYearlyAgreementText
//                 .padding(.horizontal, 20)
//                    .padding(.top, 10)
//            }
//
//            // Additional Information Text
//            additionalInfoText
//            
//        }
//        .padding(.horizontal, 20)
//        .padding(.top, 10)
//    }
//
//    // MARK: - Subviews
//
//    /// Builds the subscription agreement text with inline links.
//    private var subscriptionWeeklyAgreementText: some View {
//     
//        
//        let termsURL = URL(string: "https://www.verby.co/#/terms")!
//        let privacyURL = URL(string: "https://www.verby.co/#/privacy")!
//
//        return VStack(alignment: .center, spacing: 0) {
//            Text("This subscription automatically renews for \(iapManager.priceText(for: selectedPlan)) after the 3 days free trial. You can cancel anytime. By signing up for a free trial, you agree to the")
//                .font(.custom("SFProRoundedThin", size: 12))
//                .foregroundColor(.primary.opacity(0.7))
//                .multilineTextAlignment(.center)
//
//            HStack(spacing: 0) {
//                Link("Terms of Service", destination: termsURL)
//                    .font(.custom("SFProRoundedRegular", size: 12))
//                    .foregroundColor(.accentColor)
//                    .underline()
//
//                Text(" and ")
//                    .font(.custom("SFProRoundedThin", size: 12))
//                    .foregroundColor(.primary.opacity(0.7))
//
//                Link(" Privacy Policy.", destination: privacyURL)
//                    .font(.custom("SFProRoundedRegular", size: 12))
//                    .foregroundColor(.accentColor)
//                    .underline()
//            }
//            .multilineTextAlignment(.center)
//        }
//    }
//
//        private var subscriptionYearlyAgreementText: some View {
//        let termsURL = URL(string: "https://www.verby.co/#/terms")!
//        let privacyURL = URL(string: "https://www.verby.co/#/privacy")!
//
//        return VStack(alignment: .center, spacing: 0) {
//            Text("This subscription automatically renews for \(iapManager.priceText(for: .yearly)) per year. You can cancel anytime. By subscribing, you agree to the")
//                .font(.custom("SFProRoundedThin", size: 12))
//                .foregroundColor(.primary.opacity(0.7))
//                .multilineTextAlignment(.center)
//
//            HStack(spacing: 0) {
//                Link("Terms of Service", destination: termsURL)
//                    .font(.custom("SFProRoundedRegular", size: 12))
//                    .foregroundColor(.accentColor)
//                    .underline()
//
//                Text(" and ")
//                    .font(.custom("SFProRoundedThin", size: 12))
//                    .foregroundColor(.primary.opacity(0.7))
//
//                Link("Privacy Policy.", destination: privacyURL)
//                    .font(.custom("SFProRoundedRegular", size: 12))
//                    .foregroundColor(.accentColor)
//                    .underline()
//            }
//            .multilineTextAlignment(.center)
//        }
//    }
//
//    /// Builds the additional information text below the subscription agreement.
//    private var additionalInfoText: some View {
//        
//        Text("Payment will be charged to your Apple ID account at the confirmation of purchase. The subscription automatically renews unless it's canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscription by going to your App Store account settings after purchase.")
//            .font(.custom("SFProRoundedThin", size: 12))
//            .foregroundColor( .primary.opacity(0.7))
//            .multilineTextAlignment(.center)
//            .padding(.horizontal, 20)
//            .padding(.top, 10)
//    }
//}
//
//struct CloseButton: View {
//    let action: () -> Void
//
//    var body: some View {
//        Button(action: action) {
//            Image(systemName: "xmark")
//                .font(.system(size: 24))
//                .foregroundColor(.gray.opacity(0.6))
//                .frame(width: 24, height: 24)
//        }
//        .padding([.top, .leading], 24)
//    }
//}
//
//// MARK: - Helper View for Subscription Plan Option
//
//struct PlanOptionView: View {
//     let title: String
//    let subtitle: String
//    let oldPriceText: String? = nil // Default to nil
//    let isSelected: Bool
//    let action: () -> Void // Action closure to handle selection
//    let savingsText: String? = nil // Default to nil
//    let freeTrialText: String? = nil // Default to nil
//
//    var body: some View {
//        Button(action: action) {
//            HStack {
//                // Checkmark Indicator
//                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
//                    .foregroundColor(isSelected ? Color.accentColor : Color.gray)
//                    .font(.system(size: 20))
//
//                // Plan Details
//                VStack(alignment: .leading, spacing: 2) {
//                    Text(title)
//                        .font(.custom("SFProRoundedSemibold", size: 18))
//                        .foregroundColor(.primary)
//
//                    Text(subtitle)
//                        .font(.custom("SFProRoundedRegular", size: 16))
//                        .foregroundColor(isSelected ? .primary : .gray)
//                }
//
//                Spacer()
//
//                // Savings or Free Trial Text
//                if let savingsText = savingsText {
//                    Text(savingsText)
//                        .font(.custom("SFProRoundedSemibold", size: 16))
//                        .foregroundColor(.primary)
//                }
//            }
//            .padding(8)
//            .frame(maxWidth: .infinity, alignment: .leading) // Ensure HStack fills the width
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(isSelected ? Color.accentColor : Color.gray, lineWidth: 2)
//            )
//            .background(
//                isSelected ? Color.accentColor.opacity(0.1) : Color.clear
//            )
//            .contentShape(Rectangle()) // Define the tappable area as a rectangle
//        }
//        .buttonStyle(PlainButtonStyle()) // Remove default button styling
//    }
//}
//
//// MARK: - RoundedCorner Shape
//
//
//
//struct ActivityIndicator: UIViewRepresentable {
//    @Binding var isAnimating: Bool
//    let style: UIActivityIndicatorView.Style
//
//    func makeUIView(context: Context) -> UIActivityIndicatorView {
//        let activityIndicator = UIActivityIndicatorView(style: style)
//        activityIndicator.hidesWhenStopped = true
//        return activityIndicator
//    }
//
//    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
//        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
//    }
//}
