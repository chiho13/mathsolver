import SwiftUI

/// Shared pay-wall that can be used during onboarding or inside the main app.
/// It is intentionally self-contained so other screens only need to provide a
/// closure for the close action.
struct PaywallView: View {
    @EnvironmentObject private var iap: IAPManager
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var vm = PaywallVM()

    /// Called when the user taps the X button or when a purchase finishes.
    let onClose: () -> Void
    /// If `true`, the X button is visible from the start (onboarding case).
    var showCloseImmediately: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer().frame(height: 120) // Reduced spacer to allow content under header

                    PaywallBenefitsView()
                    .padding(.top, 100)
                    
//                    ValuePropositionView()

                    PlanCardSection()
                        .environmentObject(vm)

                    PaywallContinueButton(action: {
                        await vm.purchase(iap: iap)
                    }, isDisabled: vm.isPurchasing)
                    .environmentObject(vm)

                    AuxButtonsBar(isDisabled: vm.isPurchasing, restoreAction: {
                        Task { await vm.restore(iap: iap) }
                    })

                    LegalTextView(selectedPlan: vm.selectedPlan)
                        .padding(.bottom, 24)
                }
            }
            
            // Hero / header background - now overlays the scroll content
            HeaderView()
                .frame(maxHeight: 250)
                .edgesIgnoringSafeArea(.top)

            // Close button
            // Button(action: onClose) {
            //     Image(systemName: "xmark")
            //         .font(.system(size: 20, weight: .semibold))
            //         .foregroundColor(.primary.opacity(0.6))
            //         .padding(12)
            //         .background(.thinMaterial, in: Circle())
            // }
            // .padding(.trailing, 16)
            // .padding(.top, 8)
           
        }
        .alert(item: $vm.activeAlert) { alert in
            switch alert {
            case .success:
                return Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK"), action: onClose))
            case .error(let msg):
                return Alert(title: Text("Error"), message: Text(msg), dismissButton: .default(Text("OK")))
            }
        }
        .overlay(
            Group {
                if vm.isPurchasing {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                            .scaleEffect(1.5)
                    }
                }
            }
        )
        .disabled(vm.isPurchasing)
    }
}

// MARK: - Subviews

private struct HeaderView: View {
    @Environment(\.colorScheme) private var cs
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: cs == .dark ? [Color.fromHex("#4430f2"), Color.fromHex("#2d1dd8"), Color.fromHex("#1a0f7a")] : [Color.accentColor, Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 20) {
                Image("appicon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text(NSLocalizedString("paywall-title", comment: ""))
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(cs == .dark ? Color.fromHex("#00e17b") : .white)
                    
                    Text("Get Detailed Step by Step Solution")
                        .font(.system(size: 16, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(cs == .dark ? Color.fromHex("#00e17b").opacity(0.8) : .white.opacity(0.8))
                }
            }
            .padding(.top, 20)
        }
    }
}

private struct PaywallBenefitsView: View {
    private let benefits: [String] = ["paywall-bulletpointhree", "paywall-bulletpointone", "paywall-bulletpointfour"]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(benefits, id: \.self) { key in
                HStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                        .frame(width: 24, height: 24)
                    
                    Text(LocalizedStringKey(key))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 48)
        .padding(.top, 20)
        .padding(.bottom, 20)
        // .background(Color.primary.opacity(0.03))
        // .cornerRadius(16)
        // .overlay(
        //     RoundedRectangle(cornerRadius: 16)
        //         .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        // )
        .padding(.horizontal, 20)
    }
}

private struct ValuePropositionView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Everything You Need")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Join thousands of users who create professional PDFs every day")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }
}

private struct PlanCardSection: View {
    @EnvironmentObject private var iap: IAPManager
    @EnvironmentObject private var vm: PaywallVM

    private var savingsText: String {
        guard let yearlyPrice = iap.getPrice(for: .yearly),
              let weeklyPrice = iap.getPrice(for: .weekly) else {
            return "Best value - save 70%"
        }
        
        let yearlyPriceDouble = NSDecimalNumber(decimal: yearlyPrice).doubleValue
        let weeklyPriceDouble = NSDecimalNumber(decimal: weeklyPrice).doubleValue
        
        let totalWeeklyCostForYear = weeklyPriceDouble * 52
        if totalWeeklyCostForYear <= yearlyPriceDouble {
            return "Best value - save 70%"
        }
        
        let savings = totalWeeklyCostForYear - yearlyPriceDouble
        let percentage = (savings / totalWeeklyCostForYear) * 100
        
        if percentage.isNaN || percentage.isInfinite || percentage <= 0 {
            return "Best value - save 70%"
        }
        
        return "Best value - save \(Int(percentage.rounded()))%"
    }

    var body: some View {
        let yearlyTrialSubtitle = iap.introductoryOfferDetails(for: .yearly)
        let weeklyTrialSubtitle = iap.introductoryOfferDetails(for: .weekly)

        VStack(spacing: 12) {
            PaywallPlanRow(
                plan: .yearly,
                title: yearlyTrialSubtitle ?? "Annual PRO",
                priceText: yearlyTrialSubtitle != nil ? "then \(iap.priceText(for: .yearly))/year" : "\(iap.priceText(for: .yearly))/year",
                subtitle: yearlyTrialSubtitle != nil ? "Annual PRO" : savingsText,
                badge: "BEST VALUE",
                isSelected: vm.selectedPlan == .yearly,
                onSelect: { vm.selectedPlan = .yearly },
                isTrialOffer: yearlyTrialSubtitle != nil
            )
            
            PaywallPlanRow(
                plan: .weekly,
                title: weeklyTrialSubtitle ?? "Weekly PRO",
                priceText: weeklyTrialSubtitle != nil ? "then \(iap.priceText(for: .weekly))/week" : "\(iap.priceText(for: .weekly))/week",
                subtitle: weeklyTrialSubtitle != nil ? "Weekly PRO" : "Great for homework & exams",
                badge: nil,
                isSelected: vm.selectedPlan == .weekly,
                onSelect: { vm.selectedPlan = .weekly },
                isTrialOffer: weeklyTrialSubtitle != nil
            )
        }
        .padding(.horizontal, 20)
    }
}

private struct PaywallPlanRow: View {
    let plan: SubscriptionPlan
    let title: String
    let priceText: String
    let subtitle: String
    let badge: String?
    let isSelected: Bool
    let onSelect: () -> Void
    var isTrialOffer: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Radio button
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: isTrialOffer ? .bold : .semibold))
                            .foregroundColor(isTrialOffer ? (colorScheme == .dark ? .accentColor.lighten() : .accentColor) : .primary)
                        
                        Spacer()
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange, Color.red]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text(priceText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
                          startPoint: .bottomTrailing ,
                                endPoint: .topLeading
                        ) : 
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color.gray.opacity(0.1) : Color.white,
                                colorScheme == .dark ? Color.gray.opacity(0.1) : Color.white
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? 
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                                startPoint: .bottomTrailing ,
                                endPoint: .topLeading
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? Color.accentColor.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PaywallContinueButton: View {
    let action: () async -> Void
    let isDisabled: Bool
    @EnvironmentObject private var vm: PaywallVM
    @EnvironmentObject private var iap: IAPManager
    @State private var isPressed = false

    private var buttonText: String {
        // If the yearly plan is selected and the user is eligible for a free trial,
        // show "Start Free Trial". Otherwise, show "Subscribe Now".
        if iap.introductoryOfferDetails(for: vm.selectedPlan) != nil {
            return "Try for Free"
        }
        return "Continue"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Enhanced benefit indicator
            if vm.selectedPlan == .yearly && iap.introductoryOfferDetails(for: .yearly) != nil {
                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16, weight: .medium))
                    Text("No payment now • Cancel anytime")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            } else if vm.selectedPlan == .weekly {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                    Text("Cancel anytime • No commitment")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Enhanced button with better interaction
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                Task { await action() }
            }) {
                HStack(spacing: 12) {
                    Spacer()
                    
                    if vm.selectedPlan == .yearly && iap.introductoryOfferDetails(for: .yearly) != nil {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text(buttonText)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .frame(height: 56)
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
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                )
                .shadow(color: Color.accentColor.opacity(0.5), radius: 16, x: 0, y: 8)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .scaleEffect(isPressed ? 0.97 : 1.0)
            }
            .scaleEffect(isDisabled ? 0.95 : 1.0)
            .opacity(isDisabled ? 0.6 : 1.0)
            .disabled(isDisabled)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isDisabled)
        }
        .padding(.horizontal, 20)
    }
}

private struct AuxButtonsBar: View {
    let isDisabled: Bool
    let restoreAction: () -> Void
    var body: some View {
        HStack(spacing: 24) {
            Button("Restore", action: restoreAction)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .disabled(isDisabled)
        }
        .padding(.top, 8)
    }
}

private struct LegalTextView: View {
    let selectedPlan: SubscriptionPlan
    @EnvironmentObject private var iap: IAPManager
    
    private var renewalPeriod: String {
        switch selectedPlan {
        case .weekly:
            return "per week"
        case .yearly:
            return "per year"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(legalText)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            HStack(spacing: 20) {
                Link("Terms of Service", destination: URL(string: "https://verby.co/math")!)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
                
                Link("Privacy Policy", destination: URL(string: "https://verby.co/math/privacy")!)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            
        }
    }

    private var legalText: String {
        let price = iap.priceText(for: selectedPlan)
        
        let trialInfo: String
        if let trialDetails = iap.introductoryOfferDetails(for: selectedPlan) {
            trialInfo = " after " + trialDetails.lowercased()
        } else {
            trialInfo = ""
        }
        
        return "This subscription automatically renews for \(price) \(renewalPeriod)\(trialInfo). You can cancel anytime."
    }
} 
