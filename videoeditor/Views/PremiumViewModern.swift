import SwiftUI

/// Thin wrapper kept to preserve the original API used across the code-base.
/// Internally it delegates to the new `PaywallView` component.
struct PremiumView: View {
    /// Original call-site passes a headline but we now manage copy inside `PaywallView`.
    /// Keeping the parameter avoids touching multiple files.
    var headline: String = "paywall-title"

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var iapManager: IAPManager

    var body: some View {
        PaywallView(onClose: { dismiss() })
            .environmentObject(iapManager)
    }
} 