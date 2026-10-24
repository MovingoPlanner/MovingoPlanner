//
//  AppTheme.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-24.
//

import SwiftUI
import UIKit

enum AppTheme {
    // MARK: - Backgrounds

    static let background = adaptive(
        light: UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1),
        dark: UIColor(red: 0.055, green: 0.065, blue: 0.085, alpha: 1)
    )

    static let surface = adaptive(
        light: .white,
        dark: UIColor(red: 0.105, green: 0.12, blue: 0.15, alpha: 1)
    )

    static let secondarySurface = adaptive(
        light: UIColor(red: 0.92, green: 0.94, blue: 0.97, alpha: 1),
        dark: UIColor(red: 0.14, green: 0.155, blue: 0.19, alpha: 1)
    )

    // MARK: - Text

    static let primaryText = Color.primary
    static let secondaryText = Color.secondary

    // MARK: - Borders and separators

    static let separator = adaptive(
        light: UIColor.black.withAlphaComponent(0.12),
        dark: UIColor.white.withAlphaComponent(0.10)
    )

    // MARK: - Accent

    static let accent = adaptive(
        light: UIColor(red: 0, green: 136.0 / 255.0, blue: 254.0 / 255.0, alpha: 1),
        dark: UIColor(red: 0, green: 136.0 / 255.0, blue: 254.0 / 255.0, alpha: 1)
    )

    // MARK: - Adaptive color helper

    private static func adaptive(
        light: UIColor,
        dark: UIColor
    ) -> Color {
        Color(
            UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}
