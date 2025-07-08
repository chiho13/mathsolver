//
//  IAPManager.swift
//  videoeditor
//
//  Created by Anthony Ho on 18/06/2025.
//


//
//  IAPManager.swift
//  all ears
//
//  Created by Anthony Ho on 16/01/2025.
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
class IAPManager: ObservableObject {
    @Published var products: [StoreKit.Product] = []
    @Published var isPremium: Bool = false
    @Published var activePlan: SubscriptionPlan?  // Add this property
    @Published var didCheckPremium: Bool = false
    
    // Dictionary to map SubscriptionPlan to StoreKit.Product
    var planProducts: [SubscriptionPlan: StoreKit.Product] = [:]
    
    init() {
        Task {
            await fetchProducts()
            await checkPremiumStatus()
            await listenForTransactionUpdates()
        }
    }

     private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            switch result {
            case .verified(let transaction):
                if let plan = SubscriptionPlan.allCases.first(where: { $0.rawValue == transaction.productID }) {
                    if transaction.revocationDate == nil {
                        isPremium = true
                        activePlan = plan
                        await transaction.finish()
                        print("\(plan.displayName) transaction updated successfully.")
                    }
                }
            case .unverified(_, let error):
                print("Transaction update could not be verified: \(error.localizedDescription)")
            }
        }
    }
    
    // Fetch both the subscription and lifetime products
    func fetchProducts() async {
        let productIDs = SubscriptionPlan.allCases.map { $0.rawValue }
        print("Requesting products with IDs: \(productIDs)")
        do {
            let fetchedProducts = try await StoreKit.Product.products(for: productIDs)
            self.products = fetchedProducts
            print("Fetched products: \(fetchedProducts.map { $0.id })")
            
            // Map products to their respective SubscriptionPlans
            for product in fetchedProducts {
                if let plan = SubscriptionPlan.allCases.first(where: { $0.rawValue == product.id }) {
                    planProducts[plan] = product
                    print("Mapped \(plan.displayName) to product: \(product.id)")
                }
            }
            
            // Debug: Check which plans are missing
            for plan in SubscriptionPlan.allCases {
                if planProducts[plan] == nil {
                    print("⚠️ WARNING: No product found for \(plan.displayName) (ID: \(plan.rawValue))")
                }
            }
        } catch {
            print("Error fetching products: \(error)")
        }
    }
    
    // Purchase a specific Subscription Plan
    func purchase(plan: SubscriptionPlan) async -> Bool {
        guard let product = planProducts[plan] else {
            print("Product not found for plan: \(plan.rawValue)")
            return false
        }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verification.payloadValue
                if transaction.revocationDate == nil {
                    isPremium = true
                    activePlan = plan
                    await transaction.finish()
                    print("\(plan.displayName) purchased successfully.")
                    return true
                }
                // If revocationDate is not nil, the transaction is revoked
                print("\(plan.displayName) purchase was revoked.")
                return false
            case .userCancelled:
                print("\(plan.displayName) purchase cancelled by user.")
                return false
            case .pending:
                print("\(plan.displayName) purchase is pending.")
                return false
            @unknown default:
                print("Unknown purchase result for \(plan.displayName).")
                return false
            }
        } catch {
            print("Purchase failed for \(plan.displayName): \(error)")
            return false
        }
    }
    
    
    
    // Check Premium Status by Iterating Over Current Entitlements
    func checkPremiumStatus() async {
        var premium = false
        var currentPlan: SubscriptionPlan?
        
        do {
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if let plan = SubscriptionPlan.allCases.first(where: { $0.rawValue == transaction.productID }) {
                        if transaction.revocationDate == nil {
                            premium = true
                            currentPlan = plan
                            break
                        }
                    }
                case .unverified(_, let error):
                    print("Transaction could not be verified: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error checking premium status: \(error)")
        }
        isPremium = premium
        activePlan = currentPlan
        didCheckPremium = true
        print("Premium status: \(isPremium)")
        print("Premium status: \(isPremium), Active Plan: \(currentPlan?.displayName ?? "None")")
    }

    func priceText(for plan: SubscriptionPlan) -> String {
        guard let product = planProducts[plan] else { 
            print("⚠️ No product found for \(plan.displayName) (ID: \(plan.rawValue))")
            print("Available products: \(planProducts.keys.map { $0.displayName })")
            return "Loading..." // Return loading text instead of empty string
        }
        // Format the price with localized currency
        return product.price.formatted(product.priceFormatStyle)
    }
    
    // Helper method to check if products are loaded
    var areProductsLoaded: Bool {
        return !planProducts.isEmpty
    }
    
//    func getPrice(for plan: SubscriptionPlan) -> Decimal? {
//        guard let product = planProducts[plan] else { return 0.00 }
//          return product.price
//    }
    
//    func getCurrencyCode(for plan: SubscriptionPlan) -> String? {
//        guard let product = planProducts[plan] else { return "" }
//          return planProducts[plan]?.priceLocale.currencyCode
//      }
    
    // Restore Purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkPremiumStatus()
            print("Purchases restored successfully.")
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
}
