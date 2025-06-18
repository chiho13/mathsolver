//
//  Colors+hex+darken+lighten.swift
//  all ears
//
//  Created by Anthony Ho on 17/01/2025.
//

import Foundation
import SwiftUI

extension Color {
    /// Returns a Color from a hex string (e.g., "#RRGGBB" or "RRGGBBAA").
    /// If the hex is invalid, it defaults to black.
    static func fromHex(_ hex: String) -> Color {
        return UIColor.fromHex(hex).map(Color.init) ?? .black
    }

    func lighter(by percentage: CGFloat = 30.0) -> Color {
        return self.adjustBrightness(by: abs(percentage))
    }

    func darker(by percentage: CGFloat = 30.0) -> Color {
        return self.adjustBrightness(by: -abs(percentage))
    }
    
    func lighten(by percentage: CGFloat = 30.0) -> Color {
        return self.mix(with: .white, amount: percentage / 100.0)
    }
    
    func darken(by percentage: CGFloat = 30.0) -> Color {
        return self.mix(with: .black, amount: percentage / 100.0)
    }
       
    func mix(with color: Color, amount: CGFloat) -> Color {
        let percentage = min(max(amount, 0), 1)
           
        guard let components1 = UIColor(self).cgColor.components,
              let components2 = UIColor(color).cgColor.components else {
            return self
        }
           
        let r1 = components1[0]
        let g1 = components1[1]
        let b1 = components1[2]
        let a1 = components1.count > 3 ? components1[3] : 1
           
        let r2 = components2[0]
        let g2 = components2[1]
        let b2 = components2[2]
        let a2 = components2.count > 3 ? components2[3] : 1
           
        let r = r1 * (1 - percentage) + r2 * percentage
        let g = g1 * (1 - percentage) + g2 * percentage
        let b = b1 * (1 - percentage) + b2 * percentage
        let a = a1 * (1 - percentage) + a2 * percentage
           
        return Color(UIColor(red: r, green: g, blue: b, alpha: a))
    }

    private func adjustBrightness(by percentage: CGFloat = 30.0) -> Color {
        UIColor(self).adjustBrightness(by: percentage).map(Color.init) ?? self
    }

    static let veryLightGray = Color(red: 0.91, green: 0.91, blue: 0.91)
}

extension UIColor {
    func adjustBrightness(by percentage: CGFloat = 30.0) -> UIColor? {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightnessValue: CGFloat = 0
        var alpha: CGFloat = 0

        if getHue(&hue, saturation: &saturation, brightness: &brightnessValue, alpha: &alpha) {
            brightnessValue += (percentage / 100.0) * brightnessValue
            brightnessValue = max(min(brightnessValue, 1.0), 0.0)
            return UIColor(hue: hue, saturation: saturation, brightness: brightnessValue, alpha: alpha)
        } else {
            return nil
        }
    }

    static func fromHex(_ hex: String) -> UIColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let length = hexSanitized.count
        let r, g, b, a: CGFloat

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
