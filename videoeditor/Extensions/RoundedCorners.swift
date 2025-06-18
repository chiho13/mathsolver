//
//  RoundedCorners.swift
//  all ears
//
//  Created by Anthony Ho on 17/01/2025.
//

import Foundation
import SwiftUI


struct RoundedCorners: Shape {
    var radius: CGFloat = 16
    var corners: UIRectCorner = [.bottomLeft, .bottomRight]
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - View Modifier Extension for Specific Corner Rounding

extension View {
    /// Applies a corner radius to specific corners of the view.
    /// - Parameters:
    ///   - radius: The radius of the corners.
    ///   - corners: The corners to apply the radius to.
    /// - Returns: A view with the specified corners rounded.
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorners(radius: radius, corners: corners))
    }
}

