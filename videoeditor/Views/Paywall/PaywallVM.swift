import Foundation
import SwiftUI

@MainActor
final class PaywallVM: ObservableObject {
    @Published var selectedPlan: SubscriptionPlan = .yearly
    @Published var isPurchasing = false
    @Published var activeAlert: ActiveAlert?

    enum ActiveAlert: Identifiable {
        case success
        case error(String)

        var id: String {
            switch self {
            case .success: return "success"
            case .error: return "error"
            }
        }

        var title: String {
            switch self {
            case .success: return "Success"
            case .error: return "Error"
            }
        }

        var message: String {
            switch self {
            case .success: return "You're all set! Purchase successful!"
            case .error(let msg): return msg
            }
        }
    }

    func purchase(iap: IAPManager) async {
        isPurchasing = true
        let success = await iap.purchase(plan: selectedPlan)
        isPurchasing = false
        if success {
            activeAlert = .success
        } else {
            activeAlert = .error("There was a problem processing your purchase. Please try again.")
        }
    }

    func restore(iap: IAPManager) async {
        isPurchasing = true
        await iap.restorePurchases()
        isPurchasing = false
        if iap.isPremium {
            activeAlert = .success
        } else {
            activeAlert = .error("No purchases found to restore.")
        }
    }
} 