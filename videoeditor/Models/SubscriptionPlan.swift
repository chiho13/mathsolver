//
//  SubscriptionPlan.swift
//  videoeditor
//
//  Created by Anthony Ho on 18/06/2025.
//


import Foundation
import StoreKit


enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case weekly = "weekly.math"
    case yearly = "yearly.math"
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .weekly:
            return "Weekly PRO"
        case .yearly:
            return "Annual PRO"
        }
    }
    
    var subtitle: String {
        switch self {
        case .weekly:
            return "Perfect for short-term projects"
        case .yearly:
            return "Best value - save 70%"
        }
    }
}
