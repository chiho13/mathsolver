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
    @Published var hasCredits: Bool = false
    
    private let ledger: FreeAllowanceLedgerProviding
    private let reviewDefaults: UserDefaults
    private let legacyCreditsKey = "previewCredits"
    private let legacyFirstLaunchKey = "creditFirstLaunch"
    private let reviewTotalCompletedSessionsKey = "reviewTotalCompletedSessions"
    private let reviewCompletedSessionsSincePromptKey = "reviewCompletedSessionsSincePrompt"
    private let reviewLastPromptVersionKey = "reviewLastPromptVersion"
    private let reviewLastPromptTimestampKey = "reviewLastPromptTimestamp"
    
    // Configuration
    private let reviewMinCompletedSessions = 3
    private let reviewCooldownDays = 30
    private let reviewRequestDelay: TimeInterval = 5
    
    private var reviewTotalCompletedSessions: Int = 0
    private var reviewCompletedSessionsSincePrompt: Int = 0
    private var reviewLastPromptVersion: String = ""
    private var reviewLastPromptTimestamp: TimeInterval = 0
    private var pendingReviewRequest: DispatchWorkItem?
    
    init(
        ledger: FreeAllowanceLedgerProviding = FreeAllowanceLedger.shared,
        reviewDefaults: UserDefaults = .standard
    ) {
        self.ledger = ledger
        self.reviewDefaults = reviewDefaults
        loadCredits()
        loadReviewPromptState()
    }
    
    /// Loads the authoritative usage count from Keychain. Existing installs are
    /// migrated once from the former UserDefaults-backed credit count.
    private func loadCredits() {
        let legacyUsedTasks: Int
        if reviewDefaults.bool(forKey: legacyFirstLaunchKey),
           reviewDefaults.object(forKey: legacyCreditsKey) != nil {
            // The old release granted four credits even though its UI comment said three.
            let oldInitialCredits = 4
            let oldRemainingCredits = max(0, reviewDefaults.integer(forKey: legacyCreditsKey))
            legacyUsedTasks = FreeAllowancePolicy.clampUsedTasks(
                oldInitialCredits - oldRemainingCredits
            )
        } else {
            legacyUsedTasks = 0
        }

        apply(
            ledger.bootstrap(usedTasks: legacyUsedTasks, now: Date()),
            operation: "load"
        )
    }
    
    private func apply(
        _ result: FreeAllowanceLedgerLoadResult,
        operation: String
    ) {
        switch result {
        case .available(let snapshot):
            remainingCredits = FreeAllowancePolicy.remainingCredits(
                usedTasks: snapshot.usedTasks
            )
            hasCredits = FreeAllowancePolicy.canStartSolve(
                usedTasks: snapshot.usedTasks
            )
            print("CreditManager: \(operation) completed with \(remainingCredits) credits remaining")

        case .missing:
            failClosed(operation: operation, reason: "missing Keychain snapshot")

        case .unavailable(let error):
            failClosed(operation: operation, reason: String(describing: error))
        }
    }

    private func failClosed(operation: String, reason: String) {
        remainingCredits = 0
        hasCredits = false
        print("CreditManager: \(operation) failed closed: \(reason)")
    }
    
    private func loadReviewPromptState() {
        reviewTotalCompletedSessions = reviewDefaults.integer(forKey: reviewTotalCompletedSessionsKey)
        reviewCompletedSessionsSincePrompt = reviewDefaults.integer(forKey: reviewCompletedSessionsSincePromptKey)
        reviewLastPromptVersion = reviewDefaults.string(forKey: reviewLastPromptVersionKey) ?? ""
        reviewLastPromptTimestamp = reviewDefaults.double(forKey: reviewLastPromptTimestampKey)
    }
    
    private func saveReviewPromptState() {
        reviewDefaults.set(reviewTotalCompletedSessions, forKey: reviewTotalCompletedSessionsKey)
        reviewDefaults.set(reviewCompletedSessionsSincePrompt, forKey: reviewCompletedSessionsSincePromptKey)
        reviewDefaults.set(reviewLastPromptVersion, forKey: reviewLastPromptVersionKey)
        reviewDefaults.set(reviewLastPromptTimestamp, forKey: reviewLastPromptTimestampKey)
    }
    
    /// Records one successfully solved task. Failed requests never reach this method.
    @discardableResult
    func recordSuccessfulSolve() -> Bool {
        guard hasCredits else {
            print("CreditManager: No credits remaining")
            return false
        }

        let usedTasks = FreeAllowancePolicy.totalCredits - remainingCredits
        let updatedUsedTasks = FreeAllowancePolicy.usedTasksAfterSuccessfulSolve(usedTasks)
        let result = ledger.checkpoint(usedTasks: updatedUsedTasks, now: Date())
        apply(result, operation: "successful solve checkpoint")

        guard case .available(let snapshot) = result else {
            return false
        }
        return snapshot.usedTasks >= updatedUsedTasks
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
