//
//  DesignSystem.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI
import UIKit

// MARK: - Font Extension
extension Font {
    /// Geist 폰트 (font-feature-settings: "rlig" 1, "calt" 1 적용, letter-spacing: 0.01em)
    static func geist(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let uiFont = UIFont.geist(size: size, weight: weight)
        return Font(uiFont)
    }
}

extension UIFont {
    /// Geist 폰트 생성 (font-feature-settings 및 letter-spacing 적용)
    static func geist(size: CGFloat, weight: Font.Weight = .regular) -> UIFont {
        // Geist 폰트 이름 매핑
        let fontName: String
        switch weight {
        case .bold:
            fontName = "Geist-Bold"
        case .semibold:
            fontName = "Geist-SemiBold"
        case .medium:
            fontName = "Geist-Medium"
        case .regular:
            fontName = "Geist-Regular"
        case .light:
            fontName = "Geist-Light"
        default:
            fontName = "Geist-Regular"
        }
        
        // 폰트 생성 시도
        guard let font = UIFont(name: fontName, size: size) else {
            // 폰트가 없으면 시스템 폰트 사용
            let uiWeight: UIFont.Weight
            switch weight {
            case .ultraLight: uiWeight = .ultraLight
            case .thin: uiWeight = .thin
            case .light: uiWeight = .light
            case .regular: uiWeight = .regular
            case .medium: uiWeight = .medium
            case .semibold: uiWeight = .semibold
            case .bold: uiWeight = .bold
            case .heavy: uiWeight = .heavy
            case .black: uiWeight = .black
            default: uiWeight = .regular
            }
            return UIFont.systemFont(ofSize: size, weight: uiWeight)
        }
        
        // font-feature-settings 적용 (rlig, calt)
        // iOS 15.0 이상에서는 기본적으로 ligatures가 활성화되어 있으므로
        // iOS 14 이하에서만 명시적으로 적용
        let descriptor = font.fontDescriptor
        if #available(iOS 15.0, *) {
            // iOS 15.0 이상: 기본 폰트 사용 (ligatures는 기본적으로 활성화)
            return font
        } else {
            // iOS 14 이하: 기존 방식 사용
            let featureSettings: [[UIFontDescriptor.FeatureKey: Any]] = [
                [.featureIdentifier: kLigaturesType, .typeIdentifier: kContextualLigaturesOnSelector],
                [.featureIdentifier: kLigaturesType, .typeIdentifier: kRequiredLigaturesOnSelector]
            ]
            let newDescriptor = descriptor.addingAttributes([.featureSettings: featureSettings])
            return UIFont(descriptor: newDescriptor, size: size)
        }
    }
}

extension Color {
    // MARK: - Primary Colors
    /// Primary accent color for the app: #f3a9c0
    static let appPrimary = Color(red: 243/255.0, green: 169/255.0, blue: 192/255.0)
    
    // MARK: - Background Colors
    /// Primary background color (top): #FFF6F6
    static let appBackgroundTop = Color(red: 255/255.0, green: 246/255.0, blue: 246/255.0)
    /// Primary background color (bottom): #F7C8D9
    static let appBackgroundBottom = Color(red: 247/255.0, green: 200/255.0, blue: 217/255.0)
    /// Primary background color: #fce8ee (legacy)
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
    /// Header background color: #FFF0F3 60% opacity
    static let appHeaderBackground = Color(red: 255/255.0, green: 240/255.0, blue: 243/255.0).opacity(0.6)
    
    // MARK: - Text Colors
    /// Primary text color: #6B4423 (진한 쿠키 브라운)
    static let appTextPrimary = Color(red: 107/255.0, green: 68/255.0, blue: 35/255.0)
    /// Secondary text color: #8B6F47 (밝은 쿠키 브라운)
    static let appTextSecondary = Color(red: 139/255.0, green: 111/255.0, blue: 71/255.0)
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
    /// Card border color: #000000 10% opacity
    static let appCardBorder = Color(red: 0/255.0, green: 0/255.0, blue: 0/255.0).opacity(0.1)
    /// Ring color: #b87b8f
    static let appRing = Color(red: 184/255.0, green: 123/255.0, blue: 143/255.0)
    
    // MARK: - Shadow Colors
    /// Card shadow color: warm beige #E8D4C8
    static let appShadow = Color(red: 232/255.0, green: 212/255.0, blue: 200/255.0)
    /// Delete action background color: #d86a57 with 0.3 opacity
    static let appDeleteBackground = Color(red: 216/255.0, green: 106/255.0, blue: 87/255.0).opacity(0.3)
    
    // MARK: - Card Color Palettes
    /// Card palette 1: Strawberry Cream - 하얀끼가 더 섞인 밝은 색상
    static let cardStrawberryBackground = Color(red: 253/255.0, green: 235/255.0, blue: 242/255.0)
    static let cardStrawberryAccent = Color(red: 247/255.0, green: 179/255.0, blue: 202/255.0)
    
    /// Card palette 2: Pistachio Mint - 하얀끼가 더 섞인 밝은 색상
    static let cardPistachioBackground = Color(red: 239/255.0, green: 247/255.0, blue: 239/255.0)
    static let cardPistachioAccent = Color(red: 196/255.0, green: 224/255.0, blue: 196/255.0)
    
    /// Card palette 3: Lemon Shortbread - 하얀끼가 더 섞인 밝은 색상
    static let cardLemonBackground = Color(red: 255/255.0, green: 248/255.0, blue: 223/255.0)
    static let cardLemonAccent = Color(red: 255/255.0, green: 224/255.0, blue: 181/255.0)
    
    /// Card palette 4: Berry Frost - 하얀끼가 더 섞인 밝은 색상
    static let cardBerryBackground = Color(red: 245/255.0, green: 239/255.0, blue: 250/255.0)
    static let cardBerryAccent = Color(red: 213/255.0, green: 181/255.0, blue: 219/255.0)
    
    /// Card palette 5: Cookie Dough - 하얀끼가 더 섞인 밝은 색상
    static let cardCookieBackground = Color(red: 253/255.0, green: 248/255.0, blue: 237/255.0)
    static let cardCookieAccent = Color(red: 246/255.0, green: 224/255.0, blue: 183/255.0)
    
    /// Card palette 6: Orange - 하얀끼가 더 섞인 밝은 색상
    static let cardOrangeBackground = Color(red: 255/255.0, green: 240/255.0, blue: 224/255.0)
    static let cardOrangeAccent = Color(red: 255/255.0, green: 196/255.0, blue: 156/255.0)
    
    /// Card palette 7: Hot Pink - 하얀끼가 더 섞인 밝은 색상
    static let cardHotPinkBackground = Color(red: 255/255.0, green: 224/255.0, blue: 242/255.0)
    static let cardHotPinkAccent = Color(red: 255/255.0, green: 159/255.0, blue: 200/255.0)
    
    /// Card palette 8: Light Brown - 하얀끼가 더 섞인 밝은 색상
    static let cardLightBrownBackground = Color(red: 249/255.0, green: 238/255.0, blue: 223/255.0)
    static let cardLightBrownAccent = Color(red: 224/255.0, green: 196/255.0, blue: 166/255.0)
    
    /// Cookie color for settings icon: #8B6F47 (밝은 쿠키 브라운)
    static let appCookieColor = Color(red: 139/255.0, green: 111/255.0, blue: 71/255.0)
    
    // MARK: - Alert Colors
    /// Alert background color: #1a1412 (using foreground color)
    static let appAlertBackground = Color(red: 26/255.0, green: 20/255.0, blue: 18/255.0)
    /// Alert text color: #ffffff
    static let appAlertText = Color(red: 255/255.0, green: 255/255.0, blue: 255/255.0)
    /// Alert dismiss button color: #d86a57 (using destructive color)
    static let appAlertDismiss = Color(red: 216/255.0, green: 106/255.0, blue: 87/255.0)
}
