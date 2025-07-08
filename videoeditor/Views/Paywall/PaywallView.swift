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
            // Hero / header background
            HeaderView()
                .frame(maxHeight: 260)
                .edgesIgnoringSafeArea(.top)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer().frame(height: 240) // Push below hero

                    BenefitsView(selectedPlan: $vm.selectedPlan)

                    PlanCardsSection()

                    ContinueButton(action: {
                        await vm.purchase(iap: iap)
                    }, isDisabled: vm.isPurchasing, selectedPlan: vm.selectedPlan)

                    AuxButtonsBar(isDisabled: vm.isPurchasing, restoreAction: {
                        Task { await vm.restore(iap: iap) }
                    })

                    LegalTextView(selectedPlan: vm.selectedPlan)
                        .padding(.bottom, 24)
                }
            }

            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.6))
                    .padding(12)
                    .background(.thinMaterial, in: Circle())
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
           
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
                gradient: Gradient(colors: cs == .dark ? [Color.fromHex("#4430f2"), Color.fromHex("#2d1dd8")] : [Color.accentColor, Color.accentColor.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 16) {
                Image("icon100")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                Text(NSLocalizedString("paywall-title", comment: ""))
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LinearGradient(colors: [.white, .white.opacity(0.8)], startPoint: .top, endPoint: .bottom))
            }
            .padding(.top, 60)
        }
    }
}
//
//private struct BenefitsView: View {
//    private let benefits: [String] = ["paywall-bulletpointone", "paywall-bulletpointtwo", "paywall-bulletpointhree", "paywall-bulletpointfour"]
//    var body: some View {
//        VStack(spacing: 14) {
//            ForEach(benefits, id: \.self) { key in
//                HStack(spacing: 12) {
//                    Image(systemName: "sparkles")
//                        .foregroundColor(.accentColor)
//                    Text(LocalizedStringKey(key))
//                        .font(.subheadline)
//                        .foregroundColor(.primary)
//                        .fixedSize(horizontal: false, vertical: true)
//                    Spacer()
//                }
//            }
//        }
//        .padding()
//        .background(Color.primary.opacity(0.05))
//        .cornerRadius(16)
//        .padding(.horizontal)
//    }
//}

private struct PlanCardsSection: View {
    @EnvironmentObject private var iap: IAPManager

    var body: some View {
        VStack(spacing: 16) {
            PlanCard(title: "Annual PRO",
                     priceText: "\(iap.priceText(for: .yearly))/year",
                     badge: nil)

            // PlanCard(title: "Weekly PRO",
            //          priceText: "\(iap.priceText(for: .weekly))/week",
            //          badge: nil,
            //          isSelected: selectedPlan == .weekly,
            //          onSelect: { selectedPlan = .weekly })
        }
        .padding(.horizontal)
    }
}

private struct PlanCard: View {
    let title: String
    let priceText: String
    let badge: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(priceText).font(.subheadline)
            }
            Spacer()
            if let badge {
                Text(badge)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

//private struct ContinueButton: View {
//    let isDisabled: Bool
//    let action: () -> Void
//    var body: some View {
//        Button(action: action) {
//            HStack {
//                Spacer()
//                Text("Continue").font(.headline).foregroundColor(.white)
//                Image(systemName: "chevron.right").foregroundColor(.white)
//                Spacer()
//            }
//            .padding()
//            .background(Color.accentColor)
//            .cornerRadius(12)
//        }
//        .disabled(isDisabled)
//        .opacity(isDisabled ? 0.6 : 1)
//        .padding(.horizontal)
//    }
//}

private struct AuxButtonsBar: View {
    let isDisabled: Bool
    let restoreAction: () -> Void
    var body: some View {
        HStack(spacing: 24) {
            Button("Restore Purchases", action: restoreAction)
                .font(.footnote)
                .foregroundColor(.gray)
                .disabled(isDisabled)
        }
    }
}

private struct LegalTextView: View {
    let selectedPlan: SubscriptionPlan
    @EnvironmentObject private var iap: IAPManager
    var body: some View {
        let price = iap.priceText(for: selectedPlan)
        VStack(spacing: 8) {
            Text("This subscription automatically renews for \(price). Cancel anytime. Payment will be charged to your Apple ID at confirmation of purchase.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://verby.co/phototopdf")!)
                    .font(.footnote)
                    .foregroundColor(.blue)
                
                Link("Privacy Policy", destination: URL(string: "https://verby.co/phototopdf/privacy")!)
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
    }
} 
