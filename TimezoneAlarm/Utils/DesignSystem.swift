//
//  DesignSystem.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors
    /// Primary accent color for the app: #f3a9c0
    static let appPrimary = Color(red: 243/255.0, green: 169/255.0, blue: 192/255.0)
    
    // MARK: - Background Colors
    /// Primary background color: #fce8ee
    static let appBackground = Color(red: 252/255.0, green: 232/255.0, blue: 238/255.0)
    /// Secondary background color: #fff6f6
    static let appSecondaryBackground = Color(red: 255/255.0, green: 246/255.0, blue: 246/255.0)
    /// Card background color: #fff9f9
    static let appCardBackground = Color(red: 255/255.0, green: 249/255.0, blue: 249/255.0)
    /// Button background color: #fbf3f0
    static let appButtonBackground = Color(red: 251/255.0, green: 243/255.0, blue: 240/255.0)
    /// Input background color: #fbf3f0
    static let appInputBackground = Color(red: 251/255.0, green: 243/255.0, blue: 240/255.0)
    /// Muted background color: #f1e8e8
    static let appMutedBackground = Color(red: 241/255.0, green: 232/255.0, blue: 232/255.0)
    /// Popover background color: #ffffff
    static let appPopoverBackground = Color(red: 255/255.0, green: 255/255.0, blue: 255/255.0)
    
    // MARK: - Text Colors
    /// Primary text color: #1a1412
    static let appTextPrimary = Color(red: 26/255.0, green: 20/255.0, blue: 18/255.0)
    /// Secondary text color: #2a1f1c
    static let appTextSecondary = Color(red: 42/255.0, green: 31/255.0, blue: 28/255.0)
    /// Text color on primary background: #ffffff
    static let appTextOnPrimary = Color(red: 255/255.0, green: 255/255.0, blue: 255/255.0)
    /// Muted text color: #6d5e5c
    static let appTextMuted = Color(red: 109/255.0, green: 94/255.0, blue: 92/255.0)
    /// Card foreground color: #2a1f1c
    static let appCardForeground = Color(red: 42/255.0, green: 31/255.0, blue: 28/255.0)
    
    // MARK: - Accent Colors
    /// Accent color: #b8d8b8
    static let appAccent = Color(red: 184/255.0, green: 216/255.0, blue: 184/255.0)
    /// Accent foreground color: #4b2f26
    static let appAccentForeground = Color(red: 75/255.0, green: 47/255.0, blue: 38/255.0)
    
    // MARK: - Semantic Colors
    /// Error/Destructive color: #d86a57
    static let appError = Color(red: 216/255.0, green: 106/255.0, blue: 87/255.0)
    /// Success color: #b8d8b8 (using accent color)
    static let appSuccess = Color(red: 184/255.0, green: 216/255.0, blue: 184/255.0)
    /// Warning color: #d86a57 (using destructive color)
    static let appWarning = Color(red: 216/255.0, green: 106/255.0, blue: 87/255.0)
    /// Destructive color: #d86a57
    static let appDestructive = Color(red: 216/255.0, green: 106/255.0, blue: 87/255.0)
    /// Text color on destructive background: #ffffff
    static let appTextOnDestructive = Color(red: 255/255.0, green: 255/255.0, blue: 255/255.0)
    
    // MARK: - Interactive Colors
    /// Selected state color: #f3a9c0 (same as primary)
    static let appSelected = Color(red: 243/255.0, green: 169/255.0, blue: 192/255.0)
    /// Disabled state color: #f1e8e8 (using muted background)
    static let appDisabled = Color(red: 241/255.0, green: 232/255.0, blue: 232/255.0)
    
    // MARK: - Border & Ring Colors
    /// Border color: #e8dcdc
    static let appBorder = Color(red: 232/255.0, green: 220/255.0, blue: 220/255.0)
    /// Ring color: #b87b8f
    static let appRing = Color(red: 184/255.0, green: 123/255.0, blue: 143/255.0)
    
    // MARK: - Shadow Colors
    /// Card shadow color
    static let appShadow = Color.black.opacity(0.1)
    /// Delete action background color: #d86a57 with 0.3 opacity
    static let appDeleteBackground = Color(red: 216/255.0, green: 106/255.0, blue: 87/255.0).opacity(0.3)
    
    // MARK: - Alert Colors
    /// Alert background color: #1a1412 (using foreground color)
    static let appAlertBackground = Color(red: 26/255.0, green: 20/255.0, blue: 18/255.0)
    /// Alert text color: #ffffff
    static let appAlertText = Color(red: 255/255.0, green: 255/255.0, blue: 255/255.0)
    /// Alert dismiss button color: #d86a57 (using destructive color)
    static let appAlertDismiss = Color(red: 216/255.0, green: 106/255.0, blue: 87/255.0)
}
