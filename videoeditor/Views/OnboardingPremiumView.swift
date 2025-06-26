//
//  OnboardingPremiumView.swift
//  videoeditor
//
//  Created by Anthony Ho on 18/06/2025.
//


//
//  onBoardingPremiumView.swift
//  all ears
//
//  Created by Anthony Ho on 19/01/2025.
//

import Foundation
import SwiftUI


struct LegacyOnboardingPremiumView: View {
    @Environment(\.colorScheme) var colorScheme
//    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var iapManager: IAPManager // Access IAPManager from the environment
    @Environment(\.openURL) var openURL // Environment variable to handle URL opening

    // State variables
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isPurchasing: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    @Binding var showPremView: Bool
    
    @State private var showPreviewCreditsSheet = false
    
    var isSmallScreen: Bool {
        UIScreen.main.bounds.height <= 667 // iPhone SE height
    }
    
    @State private var activeAlert: ActiveAlert?
    
    @State private var creditsLeft = 5
    
    private var store: NSUbiquitousKeyValueStore {
           return NSUbiquitousKeyValueStore.default
       }
    private let key = "trialCredits"

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
                
                ScrollView {
                    
                        VStack(spacing: 20) {
                            
                            TopSectionView(selectedPlan: $selectedPlan, isSmallScreen: isSmallScreen, headline: "paywall-title")
                            
                            BottomSectionView(
                                isSmallScreen: isSmallScreen,
                                selectedPlan: $selectedPlan,
                                iapManager: iapManager,
                                purchaseAction: purchaseSelectedPlan,
                                restoreAction: restorePurchases,
                                colorScheme: colorScheme,
                                isPurchasing: isPurchasing
                            )
                            .padding(.top, 50)
                            .padding(.horizontal, 6)
                        }
                        
                        .padding(.bottom, isSmallScreen ? 20 : 0) // Add padding for small screens
                            
                }
                
                
                // Close Button
                VStack {
                    HStack {
                        Spacer()
                        
                        HStack {
//                            Text("Free 8 minutes")
//                                .font(.system(size: 12, weight: .semibold))
                            
                            CloseButton(action: {
                                showPremView = false
                            })
                            .transition(.opacity)
                            .opacity(closeButtonOpacity)
                        }

                      
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
//                Task {
//                    await loadCredits()
//                }
                // Replace CircularProgressView with CloseButton after the progress animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeIn(duration: 1.0)) {
                        closeButtonOpacity = 1.0
                    }
                }
            }
            .sheet(isPresented: $showPreviewCreditsSheet) {
                VStack(alignment: .leading) {
                    
                    Text("Try Ekto for \(creditsLeft) credits for free")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .padding([.vertical, .horizontal])
                    
                    Text("30-second limit per session")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding([.horizontal])
                    
                    HStack(alignment: .center, spacing: 0) {
                        Text("By continuing you agree to our ")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        Text(" terms")
                            .font(.footnote)
                            .foregroundColor(.blue)
                            .underline()
                            .onTapGesture {
                                openURL("http://verby.co/ekto/terms")
                            }
                        
                        Text(" and ")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        
                        Text(" privacy policy.")
                            .font(.footnote)
                            .foregroundColor(.blue)
                            .underline()
                            .onTapGesture {
                                openURL("http://verby.co/ekto/privacy")
                            }
                    }
                    .multilineTextAlignment(.center)
                    .padding([.horizontal])
                    .padding(.vertical, 10)
                    
                    GetStarted(showPremView: $showPremView)
                }
                .presentationDetents([.height(250)])
            }
            .alert(item: $activeAlert) { alertType in
                switch alertType {
                case .success:
                    return Alert(
                        title: Text("Success"),
                        message: Text("You're all set! Purchase successful!"),
                        dismissButton: .default(Text("OK"), action: {
                            //                        dismiss()
                            
                            showPremView = false
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
    
    func openURL(_ urlString: String) {
          if let url = URL(string: urlString) {
              // For SwiftUI versions supporting @Environment
              #if canImport(UIKit)
              UIApplication.shared.open(url)
              #endif
          }
      }
    
    func loadCredits() async {
        let storedCredits = store.longLong(forKey: key)
        DispatchQueue.main.async {
            self.creditsLeft = Int(storedCredits) // Default to 60 if no value is found
        }
    }


   private func purchaseSelectedPlan() async {
    isPurchasing = true
    let success = await iapManager.purchase(plan: selectedPlan)
    isPurchasing = false
    if success {
//        activeAlert = .success
        showPremView = false
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

// MARK: - Subviews

// struct BackgroundGradient: View {
//     var body: some View {
//         LinearGradient(
//             gradient: Gradient(colors: [
//                 Color.accentColor.darken(by: 20),
//                 Color.accentColor.darken(by: 20).opacity(0.7) // Adjusted for visual effect
//             ]),
//             startPoint: .top,
//             endPoint: .bottom
//         )
//         .ignoresSafeArea()
//     }
// }



struct BackgroundGradient: View {
    @Environment(\.colorScheme) var colorScheme // Access the color scheme

    var body: some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.black : Color.white) // Use black for dark mode, white for light mode
            .ignoresSafeArea()
    }
}

struct TopSectionView: View {
    @Binding var selectedPlan: SubscriptionPlan
    let isSmallScreen: Bool
    let headline: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
//            Image("icon100") // Use the app icon
//                .resizable()
//                .scaledToFit()
//                .frame(width: 100, height: 100)
//                .cornerRadius(24)
            VStack(alignment: .leading, spacing: 20) { // Changed from VStack to HStack
                
                let localizedString = NSLocalizedString(headline, comment: "")
                let processedString = localizedString.replacingOccurrences(of: "\\n", with: "\n")
                
                let unlimitedColor = colorScheme == .dark ? Gradient(colors: [
                    .purple.lighten(),
                    .pink.lighten()
                 ]) : Gradient(colors: [
                    .purple,
                    .pink
                 ])
                Text(processedString)
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.accentColor)
                    .overlay(
                        LinearGradient(
                             gradient:   Gradient(colors: [
                                .primary,
                                .gray
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(
                            Text(processedString)
                                .font(.largeTitle.weight(.bold))
                        )
                    )
                    .lineLimit(3)
                    .multilineTextAlignment(.center) // Center each line of text
                    .frame(maxWidth: .infinity, alignment: .center) // Center the text horizontally in the VStack
                    .padding(.vertical, 32)
                   
                
                BenefitsView(selectedPlan: $selectedPlan)
                    .padding()
                    .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.accentColor.opacity(0.07))
                    .cornerRadius(16)
                 
            }
            .padding(.horizontal, 20)

        }
        .padding(.top, 40)
        
    }

}

struct BenefitsView: View {
    @Binding var selectedPlan: SubscriptionPlan
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
//            BenefitItem(text: "paywall-bulletpointone", selectedPlan: selectedPlan)
            
            if selectedPlan == .yearly {
                BenefitItem(text: "paywall-twohours", selectedPlan: selectedPlan)
            } else {
                BenefitItem(text: "paywall-bulletpointtwo", selectedPlan: selectedPlan)
            }
          
            BenefitItem(text: "paywall-bulletpointhree", selectedPlan: selectedPlan)
            BenefitItem(text: "paywall-bulletpointfour", selectedPlan: selectedPlan)
        }
        .padding(.vertical, 20)
    }
}

struct BenefitItem: View {
    let text: LocalizedStringKey
    let color: Color = .primary
    let selectedPlan: SubscriptionPlan // Added selectedPlan parameter
    @Environment(\.colorScheme) var colorScheme
    
    // Define special colors for weeklymax
    private var circleColor: some ShapeStyle {
     
        return colorScheme == .dark ?
            LinearGradient(
                gradient: Gradient(colors: [Color.teal, Color.fromHex("#1643d4")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ) :
            LinearGradient(
                gradient: Gradient(colors: [Color.cyan, Color.accentColor]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
    }
    
    private var starColor: Color {
         .orange
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
//                Circle()
//                    .fill(circleColor)
//                    .opacity(0.8)
//                    .frame(width: 28, height: 28)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor( colorScheme == .dark ?   Color.fromHex("#60A5FA") :  Color.fromHex("#4430f2"))
            }
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}




struct BottomSectionView: View {
    let isSmallScreen: Bool
    @Binding var selectedPlan: SubscriptionPlan
    let iapManager: IAPManager
    let purchaseAction: () async -> Void
    let restoreAction: () async -> Void
    let colorScheme: ColorScheme
    let isPurchasing: Bool // Receive the purchasing state

    var body: some View {
        VStack(spacing: 12) {
            
            VStack(spacing: 4) {
//                Text("No commitment - cancel anytime")
//                    .font(.system(size: 12, weight: .regular))
//                    .foregroundColor(.primary)
//                    .padding(.bottom, 16)
                
                ZStack(alignment: .topLeading) {
                    
                    PlanSelectionRow(
                        title: "Annual PRO",
                        oldPrice: calculateOldPrice(from: iapManager.priceText(for: .yearly)),
                        newPrice: "\(iapManager.priceText(for: .yearly))/year",
                        freeTrialInfo: "7 Days FREE",
                        isSelected: selectedPlan == .yearly,
                        onSelect: {
                            withAnimation { selectedPlan = .yearly }
                        },
                        colorScheme: colorScheme
                    )
                    Text("Best Deal")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.fromHex("#4430f2"), Color.accentColor]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .offset(x: 16, y: -12)

                }
                .padding(.bottom, 8)
                
                
                PlanSelectionRow(
                    title: "Weekly PRO",
                    oldPrice: nil,
                    newPrice: "\(iapManager.priceText(for: .weekly))/week",
                    freeTrialInfo: nil, // No free trial info for weekly plan
                    isSelected: selectedPlan == .weekly,
                    onSelect: {
                        withAnimation { selectedPlan = .weekly }
                    },
                    colorScheme: colorScheme
                )
                .padding(.bottom, 8)
                
                
         
               

            }.padding()
            
//            if selectedPlan == .weeklyunlimited {
//               
//                VStack(alignment: .center, spacing: 4) {
//                    HStack(spacing: 0) {
//                        Text("Perfect for conferences – remember to cancel")
//                            .font(.system(size: 14, weight: .semibold))
//                            .foregroundColor(colorScheme == .dark ? .purple.lighten() : .purple)
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .center)
//                .padding(.bottom, 16)
//
//            }
            
            
//            if selectedPlan == .yearly {
//               
//                let grayColor = colorScheme == .dark ? Color.gray.lighten() : Color.gray
//                
//                VStack(alignment: .center, spacing: 4) {
//                    // First line: Free trial offer
//                    HStack(spacing: 0) {
//                        Text("Unlock")
//                            .font(.system(size: 14, weight: .semibold))
//                            .foregroundColor(grayColor)
//                        Text(" free access for 3 days")
//                            .font(.system(size: 14, weight: .semibold))
//                            .foregroundColor(colorScheme == .dark ? .accentColor.lighten() : .accentColor)
//                        Text(" then ")
//                            .font(.system(size: 14, weight: .semibold))
//                            .foregroundColor(grayColor)
//                        ThickStrikethroughText(text: calculateOldPrice(from: iapManager.priceText(for: .yearly)), grayColor: grayColor)
//                    }
//                    // Second line: Pricing details
//                    HStack(spacing: 0) {
//                        Text(" \(iapManager.priceText(for: .yearly))/year (\(calculateMonthly(from: iapManager.priceText(for: .yearly)))/month)")
//                            .font(.system(size: 14, weight: .semibold))
//                            .foregroundColor(grayColor)
//                    }
//                }
//                .frame(maxWidth: .infinity, alignment: .center)
//                .padding(.bottom, 16)
//
//
//            }
            
            ContinueButton(action: purchaseAction, isDisabled: isPurchasing, selectedPlan: selectedPlan)
            
            VStack(spacing: 10) {
            RestorePurchasesButton(action: restoreAction, isDisabled: isPurchasing)
//                       TermsButton(subscriptionInfoText: SubscriptionInfoText(selectedPlan: selectedPlan, iapManager: iapManager))
                
                SubscriptionInfoText(selectedPlan: selectedPlan, iapManager: iapManager)
                    .frame(height: 200)
            }
//            SubscriptionInfoText(selectedPlan: selectedPlan, iapManager: iapManager)

//            Spacer()
        }
//        .background(
//            colorScheme == .light ? Color.white.opacity(0.9) : Color.black.opacity(0.8)
//        )
        .cornerRadius(20, corners: [.topLeft, .topRight]) // Rounded top corners
        .ignoresSafeArea(edges: .bottom) // Cover safe area at the bottom
    }

   private func calculateOldPrice(from weeklyPriceText: String) -> String {
    // Extract numeric value and currency symbol using regex
    guard let (numericValue, currencySymbol) = extractPriceComponents(from: weeklyPriceText) else {
        return "N/A"
    }

    // Calculate the annual price by multiplying the weekly price by 52
    let oldPriceNumber = numericValue * 2

    // Format the annual price back to a currency string using the extracted currency symbol
    let formattedOldPrice = formatPrice(oldPriceNumber, with: currencySymbol)
    return formattedOldPrice ?? "N/A"
}
    
    private func calculateMonthly(from weeklyPriceText: String) -> String {
     // Extract numeric value and currency symbol using regex
     guard let (numericValue, currencySymbol) = extractPriceComponents(from: weeklyPriceText) else {
         return "N/A"
     }

     // Calculate the annual price by multiplying the weekly price by 52
     let oldPriceNumber = numericValue / 12

     // Format the annual price back to a currency string using the extracted currency symbol
     let formattedOldPrice = formatPrice(oldPriceNumber, with: currencySymbol)
     return formattedOldPrice ?? "N/A"
 }

private func extractPriceComponents(from priceString: String) -> (Double, String)? {
    // Use regex to find the first currency symbol and numeric value
    let regex = try? NSRegularExpression(pattern: "([A-Za-z]{1,3}\\$|[A-Za-z]{1,3}|[\\p{Sc}])?\\s*([0-9]+(?:\\.[0-9]+)?)", options: [])

    let nsString = priceString as NSString
    guard let match = regex?.firstMatch(in: priceString, options: [], range: NSRange(location: 0, length: nsString.length)) else {
        return nil
    }

    // Extract currency symbol and numeric value
    let currencySymbol = match.range(at: 1).location != NSNotFound ? nsString.substring(with: match.range(at: 1)) : ""
    let numberString = nsString.substring(with: match.range(at: 2))
    guard let numericValue = Double(numberString) else {
        return nil
    }

    return (numericValue, currencySymbol)
}

private func formatPrice(_ price: Double, with currencySymbol: String) -> String? {
    // Format the price with the extracted currency symbol
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .currency
    numberFormatter.currencySymbol = currencySymbol
    return numberFormatter.string(from: NSNumber(value: price))
}

}

struct PlanSelectionRow: View {
    let title: String             // Use a plain String for easy manipulation
    let oldPrice: String?         // e.g. "£259.48"
    let newPrice: String?         // e.g. "£24.99 per year"
    let freeTrialInfo: String?    // Optional free trial info for annual plan

    let isSelected: Bool
    let onSelect: () -> Void
    let colorScheme: ColorScheme
    
 
     
    
    var body: some View {
        let grayColor = colorScheme == .dark ? Color.gray.lighten() : Color.gray
        
      
        Button(action: onSelect) {
            HStack {
                // Left side: plan title with colour-coded substring
                titleView
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Right side: pricing/free trial text
               // Right side: pricing/free trial text
                if let freeTrialInfo = freeTrialInfo {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(LocalizedStringKey(freeTrialInfo))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : Color.fromHex("#4430f2"))
                        if let newPrice = newPrice, let oldPrice = oldPrice {
                            
                            HStack(spacing: 4) {
                                Text("then")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                ThickStrikethroughText(text: oldPrice, grayColor: grayColor)
                                Text(newPrice)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                       
                        }
                    }
                } else if let newPrice = newPrice {
                    Text(newPrice)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(height: 56)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ?  Color.fromHex("#4430f2").opacity(0.05) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? (colorScheme == .dark ? Color.fromHex("#4430f2").lighten() : Color.fromHex("#4430f2")) : Color.gray.opacity(0.5), lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // A computed view that builds the title Text with special colour for "PRO" or "LITE"
    private var titleView: Text {
        if title.contains("PRO") {
            let parts = title.components(separatedBy: "PRO")
            return Text(parts[0])
                + Text("PRO").foregroundColor(Color.fromHex("#FF5722"))
                .font(.system(size: 14, weight: .semibold))
            
                + Text(parts.count > 1 ? parts[1] : "")
        } else if title.contains("Unlimited") {
            let parts = title.components(separatedBy: "Unlimited")
            return Text(parts[0])
            + Text("Unlimited").foregroundColor(colorScheme == .dark ? Color.purple.lighten() : Color.purple)
                .font(.system(size: 14, weight: .semibold))
            
                + Text(parts.count > 1 ? parts[1] : "")
        } else {
            return Text(title)
        }
    }
}



    private func calculateDiscountText(oldPrice: String?, newPrice: String?) -> String? {
    guard let oldPrice = oldPrice, let newPrice = newPrice,
          let oldPriceValue = extractNumericValue(from: oldPrice),
          let newPriceValue = extractNumericValue(from: newPrice) else {
        return nil
    }
    
    let discount = ((oldPriceValue - newPriceValue) / oldPriceValue) * 100
    return String(format: "SAVE %.0f%%", discount)
}

private func extractNumericValue(from priceString: String) -> Double? {
    // Use a regular expression to find numbers and decimal points
    let regex = try? NSRegularExpression(pattern: "[0-9]+(?:\\.[0-9]+)?", options: [])
    let nsString = priceString as NSString
    let results = regex?.matches(in: priceString, options: [], range: NSRange(location: 0, length: nsString.length))
    
    // Join the matches to form a complete number string
    let numberString = results?.map { nsString.substring(with: $0.range) }.joined()
    
    // Convert the number string to a Double
    return numberString.flatMap { Double($0) }
}
    //  private func calculateDiscountText(oldPrice: String?, newPrice: String?) -> String? {
    //     guard let oldPrice = oldPrice, let newPrice = newPrice,
    //           let oldPriceValue = Double(oldPrice.filter("0123456789.".contains)),
    //           let newPriceValue = Double(newPrice.filter("0123456789.".contains)) else {
    //         return nil
    //     }
        
    //     let discount = ((oldPriceValue - newPriceValue) / oldPriceValue) * 100
    //     return String(format: "SAVE %.0f%%", discount)
    // }




struct ContinueButton: View {
    let action: () async -> Void
    let isDisabled: Bool
    let selectedPlan: SubscriptionPlan // Pass in selectedPlan

        private var buttonText: String {
        switch selectedPlan {
        case .yearly:
            return "Start for Free" // Updated to match 3-day trial

        default:
            return "Continue"
        }
    }

    var body: some View {
        Button(action: {
            Task { await action() }
        }) {
           
                HStack {
                    Spacer()
                    Text(buttonText) // Conditional text
                         .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right") // Add chevron icon
                        .font(.system(size: 18, weight: .semibold)) // Semi-bold chevron
                        .foregroundColor(.white)
                    Spacer()
                }
               
            .frame(maxWidth: .infinity)
            .padding()
//            .background(Color.accentColor)
            .cornerRadius(10)
        }
        .buttonStyle(PayWallPressableButtonStyle(selectedPlan: selectedPlan))
        .padding(.horizontal)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}


struct PayWallPressableButtonStyle: ButtonStyle {
    let selectedPlan: SubscriptionPlan
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(
                                    gradient: Gradient(colors:  [
//                                        Color.fromHex("#2563EB"), // Rich Blue
                                        Color.fromHex("#4430f2"),
                                        Color.fromHex("#3B82F6"), // Medium Blue
                                        Color.fromHex("#60A5FA")  // Light Blue
                                    ]),
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
            )
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}


struct RestorePurchasesButton: View {
    let action: () async -> Void
    let isDisabled: Bool // Add this parameter

    var body: some View {
        Button(action: {
            Task { await action() }
        }) {
            Text("Restore")
                .font(.system(size: 14))
                .foregroundColor(Color.gray)
                .underline()
                .padding(.top, 10)
        }
        .disabled(isDisabled) // Disable the button
        .opacity(isDisabled ? 0.6 : 1.0) // Visual feedback
    }
}

struct TermsButton: View {
     @State private var showSubscriptionInfo: Bool = false
    let subscriptionInfoText: SubscriptionInfoText // Accept the view

    var body: some View {
        Button(action: {
            showSubscriptionInfo = true
        }) {
            Text("Terms of Service & Privacy Policy")
                .font(.system(size: 14))
                .foregroundColor(Color.gray)
                .underline()
                .padding(.top, 10)
        }
         .sheet(isPresented: $showSubscriptionInfo) {
            VStack {
                subscriptionInfoText // Present the SubscriptionInfoText view
                Spacer() // Add a spacer to fill the remaining space
            }
            .frame(height: 150) // Set the height of the sheet content
            .presentationDetents([.height(150)]) // Use a custom height detent
        }
    }
}


@MainActor
struct SubscriptionInfoText: View {
    let selectedPlan: SubscriptionPlan
    let iapManager: IAPManager
    @Environment(\.openURL) var openURL // Environment variable to handle URL opening

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if selectedPlan == .weekly {
                subscriptionWeeklyAgreementText
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
            } else if selectedPlan == .yearly {
                subscriptionYearlyAgreementText
                 .padding(.horizontal, 20)
                    .padding(.top, 10)
            }

            // Additional Information Text
            additionalInfoText
            
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Subviews

    /// Builds the subscription agreement text with inline links.
    private var subscriptionWeeklyAgreementText: some View {
        let termsURL = URL(string: "https://www.verby.co/ekto/terms")!
        let privacyURL = URL(string: "https://www.verby.co/ekto/privacy")!

        return VStack(alignment: .center, spacing: 0) {
            Text("This subscription automatically renews for \(iapManager.priceText(for: selectedPlan)) per week. You can cancel anytime. By subscribing, you agree to the")
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.primary.opacity(0.7))
                .multilineTextAlignment(.center)

            HStack(spacing: 0) {
                Link("Terms of Service", destination: termsURL)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.accentColor)
                    .underline()

                Text(" and ")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.primary.opacity(0.7))

                Link(" Privacy Policy.", destination: privacyURL)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.accentColor)
                    .underline()
            }
            .multilineTextAlignment(.center)
        }
    }

        private var subscriptionYearlyAgreementText: some View {
            let termsURL = URL(string: "https://www.verby.co/ekto/terms")!
            let privacyURL = URL(string: "https://www.verby.co/ekto/privacy")!

        return VStack(alignment: .center, spacing: 0) {
            Text("This subscription automatically renews for \(iapManager.priceText(for: .yearly)) per year after 7 day trial. You can cancel anytime. By subscribing, you agree to the")
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.primary.opacity(0.7))
                .multilineTextAlignment(.center)

            HStack(spacing: 0) {
                Link("Terms of Service", destination: termsURL)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.accentColor)
                    .underline()

                Text(" and ")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.primary.opacity(0.7))

                Link("Privacy Policy.", destination: privacyURL)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.accentColor)
                    .underline()
            }
            .multilineTextAlignment(.center)
        }
    }
    
   

    /// Builds the additional information text below the subscription agreement.
    private var additionalInfoText: some View {
        Text("Payment will be charged to your Apple ID account at the confirmation of purchase. The subscription automatically renews unless it's canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscription by going to your App Store account settings after purchase.")
            .font(.system(size: 11, weight: .light))
            .foregroundColor( .primary.opacity(0.7))
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .padding(.horizontal, 20)
            .padding(.top, 10)
    }
}

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary.opacity(0.8))
                        .padding(4)
                )
        }
        .padding(.trailing, 24)
        .padding(.top, 8)
    }
}

// MARK: - Helper View for Subscription Plan Option

struct PlanOptionView: View {
     let title: String
    let subtitle: String
    let oldPriceText: String? = nil // Default to nil
    let isSelected: Bool
    let action: () -> Void // Action closure to handle selection
    let savingsText: String? = nil // Default to nil
    let freeTrialText: String? = nil // Default to nil

    var body: some View {
        Button(action: action) {
            HStack {
                // Checkmark Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.accentColor : Color.gray)
                    .font(.system(size: 20))

                // Plan Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .primary : .gray)
                }

                Spacer()

                // Savings or Free Trial Text
                if let savingsText = savingsText {
                    Text(savingsText)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading) // Ensure HStack fills the width
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.7), lineWidth: 2)
            )
            .background(
                isSelected ? Color.accentColor.opacity(0.1) : Color.clear
            )
            .contentShape(Rectangle()) // Define the tappable area as a rectangle
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
    }
}

// MARK: - RoundedCorner Shape



struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: style)
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct GetStarted: View {
    @Binding var showPremView: Bool
    
    var body: some View {
        Button(action: {
            showPremView = false
        }) {
            HStack {
                Spacer()
                Text("Get Started")
                    .font(.headline)
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
}


struct ThickStrikethroughText: View {
    let text: String
    let grayColor: Color
    var body: some View {
        ZStack {
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(grayColor)
            // Overlay a rectangle as the strikethrough line.
            Rectangle()
                .frame(height: 2) // Adjust thickness as needed
                .foregroundColor(grayColor.opacity(0.8))
                .offset(y: 1) // Adjust vertical offset if needed
        }
        .fixedSize()
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(
                    gradient: Gradient(colors: configuration.isPressed ? [Color.fromHex("#1643d4"), Color.fromHex("#2a7ae3")] : [.teal, Color.fromHex("#1643d4")]),
                    startPoint: .trailing,
                    endPoint: .leading
                )
            )
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
