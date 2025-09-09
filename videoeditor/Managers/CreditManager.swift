//
//  CreditManager.swift
//  videoeditor
//
//  Created by Assistant on [Current Date].
//

import Foundation
import SwiftUI

@MainActor
class CreditManager: ObservableObject {
    @Published var remainingCredits: Int = 0
    @Published var hasCredits: Bool = true
    
    private let userDefaults = UserDefaults.standard
    private let creditsKey = "previewCredits"
    private let firstLaunchKey = "creditFirstLaunch"
    
    // Configuration
    private let initialCredits = 2 // Give users 3 free math solutions
    
    init() {
        loadCredits()
    }
    
    /// Load credits from UserDefaults
    private func loadCredits() {
        // Check if this is the first time setting up credits
        if !userDefaults.bool(forKey: firstLaunchKey) {
            // First launch - give initial credits
            userDefaults.set(initialCredits, forKey: creditsKey)
            userDefaults.set(true, forKey: firstLaunchKey)
            remainingCredits = initialCredits
        } else {
            // Load existing credits
            remainingCredits = userDefaults.integer(forKey: creditsKey)
        }
        
        hasCredits = remainingCredits > 0
        print("CreditManager: Loaded \(remainingCredits) credits")
    }
    
    /// Save credits to UserDefaults
    private func saveCredits() {
        userDefaults.set(remainingCredits, forKey: creditsKey)
        hasCredits = remainingCredits > 0
        print("CreditManager: Saved \(remainingCredits) credits")
    }
    
    /// Use one credit (call before solving math problem)
    func useCredit() -> Bool {
        guard remainingCredits > 0 else {
            print("CreditManager: No credits remaining")
            return false
        }
        
        remainingCredits -= 1
        saveCredits()
        print("CreditManager: Used 1 credit, \(remainingCredits) remaining")
        return true
    }
    
    /// Check if user has credits available
    func canUseMathSolver() -> Bool {
        return remainingCredits > 0
    }
    
    /// Get formatted credit text for UI display
    func creditDisplayText() -> String {
        switch remainingCredits {
        case 0:
            return "No credits"
        case 1:
            return "1 credit left"
        default:
            return "\(remainingCredits) credits left"
        }
    }
    
    /// Reset credits (for testing purposes)
    func resetCredits() {
        remainingCredits = initialCredits
        saveCredits()
        print("CreditManager: Reset to \(initialCredits) credits")
    }
    
    /// Add credits (for premium users or promotions)
    func addCredits(_ amount: Int) {
        remainingCredits += amount
        saveCredits()
        print("CreditManager: Added \(amount) credits, total: \(remainingCredits)")
    }
}
