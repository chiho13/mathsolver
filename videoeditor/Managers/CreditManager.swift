//
//  CreditManager.swift
//  videoeditor
//
//  Created by Assistant on [Current Date].
//

import Foundation
import StoreKit
import SwiftUI
import UIKit

@MainActor
class CreditManager: ObservableObject {
    @Published var remainingCredits: Int = 0
    @Published var hasCredits: Bool = true
    
    private let userDefaults = UserDefaults.standard
    private let creditsKey = "previewCredits"
    private let firstLaunchKey = "creditFirstLaunch"
    private let reviewTotalCompletedSessionsKey = "reviewTotalCompletedSessions"
    private let reviewCompletedSessionsSincePromptKey = "reviewCompletedSessionsSincePrompt"
    private let reviewLastPromptVersionKey = "reviewLastPromptVersion"
    private let reviewLastPromptTimestampKey = "reviewLastPromptTimestamp"
    
    // Configuration
    private let initialCredits = 4 // Give users 3 free math solutions
    private let reviewMinCompletedSessions = 3
    private let reviewCooldownDays = 30
    private let reviewRequestDelay: TimeInterval = 5
    
    private var reviewTotalCompletedSessions: Int = 0
    private var reviewCompletedSessionsSincePrompt: Int = 0
    private var reviewLastPromptVersion: String = ""
    private var reviewLastPromptTimestamp: TimeInterval = 0
    private var pendingReviewRequest: DispatchWorkItem?
    
    init() {
        loadCredits()
        loadReviewPromptState()
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
    
    private func loadReviewPromptState() {
        reviewTotalCompletedSessions = userDefaults.integer(forKey: reviewTotalCompletedSessionsKey)
        reviewCompletedSessionsSincePrompt = userDefaults.integer(forKey: reviewCompletedSessionsSincePromptKey)
        reviewLastPromptVersion = userDefaults.string(forKey: reviewLastPromptVersionKey) ?? ""
        reviewLastPromptTimestamp = userDefaults.double(forKey: reviewLastPromptTimestampKey)
    }
    
    private func saveReviewPromptState() {
        userDefaults.set(reviewTotalCompletedSessions, forKey: reviewTotalCompletedSessionsKey)
        userDefaults.set(reviewCompletedSessionsSincePrompt, forKey: reviewCompletedSessionsSincePromptKey)
        userDefaults.set(reviewLastPromptVersion, forKey: reviewLastPromptVersionKey)
        userDefaults.set(reviewLastPromptTimestamp, forKey: reviewLastPromptTimestampKey)
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
    
    func scheduleReviewRequestAfterSolutionShownIfEligible() {
        pendingReviewRequest?.cancel()
        
        reviewTotalCompletedSessions += 1
        reviewCompletedSessionsSincePrompt += 1
        
        guard reviewTotalCompletedSessions >= reviewMinCompletedSessions else {
            saveReviewPromptState()
            return
        }
        
        guard reviewCompletedSessionsSincePrompt >= reviewMinCompletedSessions else {
            saveReviewPromptState()
            return
        }
        
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        guard reviewLastPromptVersion != currentVersion else {
            saveReviewPromptState()
            return
        }
        
        if reviewLastPromptTimestamp > 0 {
            let lastPromptDate = Date(timeIntervalSince1970: reviewLastPromptTimestamp)
            let daysSincePrompt = Date().timeIntervalSince(lastPromptDate) / 86_400
            guard daysSincePrompt >= Double(reviewCooldownDays) else {
                saveReviewPromptState()
                return
            }
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard
                let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive })
            else {
                return
            }
            
            self.reviewLastPromptTimestamp = Date().timeIntervalSince1970
            self.reviewLastPromptVersion = currentVersion
            self.reviewCompletedSessionsSincePrompt = 0
            self.saveReviewPromptState()
            SKStoreReviewController.requestReview(in: scene)
            self.pendingReviewRequest = nil
        }
        
        pendingReviewRequest = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + reviewRequestDelay, execute: workItem)
    }
    
    func cancelPendingReviewRequest() {
        pendingReviewRequest?.cancel()
        pendingReviewRequest = nil
    }
}
