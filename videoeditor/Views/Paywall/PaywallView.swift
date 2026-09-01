import SwiftUI
import UIKit

private enum PaywallTheme {
    static let mint = Color.fromHex("#6EE7B7")
    static let mintStrong = Color.fromHex("#158A54")
    static let ink = Color.fromHex("#092018")

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.fromHex("#080B0A") : Color.fromHex("#F5F7F6")
    }

    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.fromHex("#151A18") : .white
    }

    static func accent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? mint : mintStrong
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

}

private struct PaywallHeroBackground: View {
    var body: some View {
        ZStack {
            Color.fromHex("#07100D")

            LinearGradient(
                colors: [
                    Color.fromHex("#5EEAD4").opacity(0.16),
                    Color.fromHex("#6EE7B7").opacity(0.10),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

private struct PaywallScannerDecoration: View {
    private struct Dot {
        let x: CGFloat
        let y: CGFloat
        let phase: Double
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let scanLegDuration = 0.45
    private let scanPauseDuration = 3.0

    private let dots = [
        Dot(x: 0.08, y: 0.24, phase: 0.2),
        Dot(x: 0.17, y: 0.72, phase: 1.4),
        Dot(x: 0.29, y: 0.38, phase: 2.6),
        Dot(x: 0.38, y: 0.82, phase: 3.8),
        Dot(x: 0.49, y: 0.18, phase: 4.7),
        Dot(x: 0.58, y: 0.68, phase: 5.5),
        Dot(x: 0.68, y: 0.34, phase: 0.9),
        Dot(x: 0.77, y: 0.79, phase: 2.1),
        Dot(x: 0.86, y: 0.22, phase: 3.2),
        Dot(x: 0.93, y: 0.58, phase: 4.3)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { timeline in
            GeometryReader { geometry in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let scanMotionDuration = scanLegDuration * 2
                let cycleDuration = scanMotionDuration + scanPauseDuration
                let cyclePosition = time.truncatingRemainder(dividingBy: cycleDuration)
                let isScanning = cyclePosition < scanMotionDuration
                let motionProgress = min(cyclePosition / scanMotionDuration, 1)
                let scanProgress = reduceMotion
                    ? 0.5
                    : isScanning
                        ? 0.5 - (0.5 * cos(motionProgress * 2 * Double.pi))
                        : 0
                let fadeIn = min(cyclePosition / 0.10, 1)
                let fadeOut = min((scanMotionDuration - cyclePosition) / 0.14, 1)
                let scanOpacity = reduceMotion
                    ? 0.35
                    : isScanning ? max(0, min(fadeIn, fadeOut)) : 0

                ZStack {
                    ForEach(dots.indices, id: \.self) { index in
                        let dot = dots[index]
                        let pulse = reduceMotion ? 1.0 : 1.0 + (0.12 * sin(time + dot.phase))

                        Circle()
                            .fill(.white.opacity(0.16))
                            .frame(width: 4, height: 4)
                            .scaleEffect(pulse)
                            .position(
                                x: geometry.size.width * dot.x,
                                y: geometry.size.height * dot.y
                            )
                    }

                    Rectangle()
                        .fill(PaywallTheme.mint.opacity(0.55))
                        .frame(width: 2, height: geometry.size.height * 0.72)
                        .opacity(scanOpacity)
                        .position(
                            x: 12 + ((geometry.size.width - 24) * scanProgress),
                            y: geometry.size.height / 2
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Shared subscription screen used during onboarding and from the main app.
struct PaywallView: View {
    @EnvironmentObject private var iap: IAPManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var vm = PaywallVM()

    private let onClose: () -> Void

    init(
        onClose: @escaping () -> Void,
        showCloseImmediately _: Bool = false
    ) {
        self.onClose = onClose
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PaywallTheme.background(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                PaywallHeroBackground()
                    .frame(height: 220)
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    PaywallHeroView()

                    VStack(spacing: 24) {
                        PaywallBenefitsView()

                        PlanCardSection()
                            .environmentObject(vm)

                        PaywallContinueButton(
                            action: { await vm.purchase(iap: iap) },
                            isDisabled: vm.isPurchasing
                        )
                        .environmentObject(vm)

                        AuxButtonsBar(
                            isDisabled: vm.isPurchasing,
                            restoreAction: {
                                Task { await vm.restore(iap: iap) }
                            }
                        )

                        LegalTextView(selectedPlan: vm.selectedPlan)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.10), in: Circle())
            }
            .accessibilityLabel("Close")
            .padding(.top, 8)
            .padding(.trailing, 16)
        }
        .alert(item: $vm.activeAlert) { alert in
            switch alert {
            case .success:
                return Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"), action: onClose)
                )
            case .error(let message):
                return Alert(
                    title: Text("Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .overlay {
            if vm.isPurchasing {
                ZStack {
                    Color.black.opacity(0.42)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.25)

                        Text("Connecting to the App Store…")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                }
            }
        }
        .disabled(vm.isPurchasing)
    }
}

private struct PaywallHeroView: View {
    var body: some View {
        ZStack {
            PaywallHeroBackground()
            PaywallScannerDecoration()

            VStack(spacing: 16) {
                Image("Icon-App-60x60")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                VStack(spacing: 9) {
                    Text("Math Solver Pro")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.85)

                    Text("Unlimited scans and clear, step-by-step solutions.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.68))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 42)
            .padding(.bottom, 27)
        }
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: 30,
                bottomTrailingRadius: 30
            )
        )
    }
}

private struct PaywallBenefitsView: View {
    private let benefits = [
        "Unlimited photo scans",
        "Clear step-by-step explanations",
        "Help from basic math to calculus"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(benefits, id: \.self) { benefit in
                HStack(spacing: 11) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(PaywallTheme.ink)
                        .frame(width: 22, height: 22)
                        .background(PaywallTheme.mint, in: Circle())

                    Text(benefit)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PlanCardSection: View {
    @EnvironmentObject private var iap: IAPManager
    @EnvironmentObject private var vm: PaywallVM

    private var savingsText: String? {
        guard let yearlyPrice = iap.getPrice(for: .yearly),
              let weeklyPrice = iap.getPrice(for: .weekly) else {
            return nil
        }

        let yearly = NSDecimalNumber(decimal: yearlyPrice).doubleValue
        let annualizedWeekly = NSDecimalNumber(decimal: weeklyPrice).doubleValue * 52
        guard yearly > 0, annualizedWeekly > yearly else { return nil }

        let percentage = Int((((annualizedWeekly - yearly) / annualizedWeekly) * 100).rounded())
        guard (1...99).contains(percentage) else { return nil }
        return "Save \(percentage)%"
    }

    private var monthlyPriceText: String? {
        guard let yearlyPrice = iap.getPrice(for: .yearly) else { return nil }
        let monthly = NSDecimalNumber(decimal: yearlyPrice).doubleValue / 12

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current

        guard let value = formatter.string(from: NSNumber(value: monthly)) else { return nil }
        return "Just \(value)/month"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Choose your plan")
                    .font(.system(size: 21, weight: .bold, design: .rounded))

                Spacer()

                Text("Cancel anytime")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            PaywallPlanRow(
                title: "Annual",
                price: iap.priceText(for: .yearly),
                period: "per year",
                detail: iap.introductoryOfferDetails(for: .yearly)
                    ?? monthlyPriceText
                    ?? savingsText
                    ?? "Best value",
                badge: (savingsText ?? "Best value").uppercased(),
                isTrial: iap.introductoryOfferDetails(for: .yearly) != nil,
                isSelected: vm.selectedPlan == .yearly,
                onSelect: { vm.selectedPlan = .yearly }
            )

            PaywallPlanRow(
                title: "Weekly",
                price: iap.priceText(for: .weekly),
                period: "per week",
                detail: iap.introductoryOfferDetails(for: .weekly) ?? "Flexible short-term access",
                badge: nil,
                isTrial: iap.introductoryOfferDetails(for: .weekly) != nil,
                isSelected: vm.selectedPlan == .weekly,
                onSelect: { vm.selectedPlan = .weekly }
            )
        }
    }
}

private struct PaywallPlanRow: View {
    let title: String
    let price: String
    let period: String
    let detail: String
    let badge: String?
    let isTrial: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? PaywallTheme.accent(for: colorScheme) : Color.secondary.opacity(0.35),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(PaywallTheme.accent(for: colorScheme))
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.primary)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(Color.fromHex("#064E3B"))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(PaywallTheme.mint, in: Capsule())
                        }
                    }

                    HStack(spacing: 5) {
                        Text(detail)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(isTrial ? PaywallTheme.accent(for: colorScheme) : Color.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(price)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(period)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                PaywallTheme.surface(for: colorScheme),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? PaywallTheme.accent(for: colorScheme) : PaywallTheme.border(for: colorScheme),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PaywallContinueButton: View {
    let action: () async -> Void
    let isDisabled: Bool

    @EnvironmentObject private var vm: PaywallVM
    @EnvironmentObject private var iap: IAPManager

    private var trialDetails: String? {
        iap.introductoryOfferDetails(for: vm.selectedPlan)
    }

    private var buttonText: String {
        if let trialDetails {
            return "Start \(trialDetails)"
        }
        return vm.selectedPlan == .yearly ? "Continue with Annual" : "Continue with Weekly"
    }

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { await action() }
            }) {
                HStack(spacing: 10) {
                    Text(buttonText)
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(PaywallTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(PaywallTheme.mint)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.55 : 1)

            Text(trialDetails == nil ? "Secure payment through the App Store" : "No charge today • Cancel anytime")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

private struct AuxButtonsBar: View {
    let isDisabled: Bool
    let restoreAction: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button("Restore Purchases", action: restoreAction)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(PaywallTheme.accent(for: colorScheme))
            .disabled(isDisabled)
    }
}

private struct LegalTextView: View {
    let selectedPlan: SubscriptionPlan

    @EnvironmentObject private var iap: IAPManager
    @Environment(\.colorScheme) private var colorScheme

    private var renewalPeriod: String {
        selectedPlan == .weekly ? "week" : "year"
    }

    private var legalText: String {
        let price = iap.priceText(for: selectedPlan)
        if let trial = iap.introductoryOfferDetails(for: selectedPlan) {
            return "After the \(trial.lowercased()), your subscription renews automatically for \(price) per \(renewalPeriod) until cancelled."
        }
        return "Your subscription renews automatically for \(price) per \(renewalPeriod) until cancelled."
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(legalText)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 22) {
                Link("Terms", destination: URL(string: "https://verby.co/math")!)
                Link("Privacy", destination: URL(string: "https://verby.co/math/privacy")!)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(PaywallTheme.accent(for: colorScheme))
        }
    }
}
