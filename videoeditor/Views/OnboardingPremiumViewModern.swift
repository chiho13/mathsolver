import SwiftUI

/// Lightweight onboarding pay-wall that uses the shared `PaywallView`.
struct OnboardingPremiumView: View {
    @Binding var showPremView: Bool
    @EnvironmentObject private var iapManager: IAPManager

    var body: some View {
        PaywallView(onClose: { showPremView = false }, showCloseImmediately: true)
            .environmentObject(iapManager)
            // .interactiveDismissDisabled()
            // .ignoresSafeArea() 
    }
} 
