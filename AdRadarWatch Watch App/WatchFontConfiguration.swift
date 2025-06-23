import SwiftUI

// MARK: - Watch App Font Configuration
struct WatchFontConfiguration {
    
    // MARK: - Font Loading
    static func loadFonts() {
        let fontNames = [
            "Sora-Regular",
            "Sora-Medium", 
            "Sora-SemiBold",
            "Sora-Bold",
            "Sora-Light"
        ]
        
        for fontName in fontNames {
            if let url = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
    
    // MARK: - Custom Font Extensions for Watch
    static func soraFont(weight: SoraWeight, size: CGFloat) -> Font {
        switch weight {
        case .light:
            return Font.custom("Sora-Light", size: size)
        case .regular:
            return Font.custom("Sora-Regular", size: size)
        case .medium:
            return Font.custom("Sora-Medium", size: size)
        case .semibold:
            return Font.custom("Sora-SemiBold", size: size)
        case .bold:
            return Font.custom("Sora-Bold", size: size)
        }
    }
}

enum SoraWeight {
    case light
    case regular
    case medium
    case semibold
    case bold
}

// MARK: - Watch-Specific Font Styles
extension Font {
    static var watchTitle: Font {
        return WatchFontConfiguration.soraFont(weight: .semibold, size: 16)
    }
    
    static var watchHeadline: Font {
        return WatchFontConfiguration.soraFont(weight: .medium, size: 14)
    }
    
    static var watchBody: Font {
        return WatchFontConfiguration.soraFont(weight: .regular, size: 12)
    }
    
    static var watchCaption: Font {
        return WatchFontConfiguration.soraFont(weight: .regular, size: 10)
    }
    
    static var watchLargeEarnings: Font {
        return WatchFontConfiguration.soraFont(weight: .semibold, size: 18)
    }
} 