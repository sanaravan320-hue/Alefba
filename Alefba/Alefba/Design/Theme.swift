import SwiftUI
import CoreText

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Paper & ink palette.
enum Ink {
    static let paper = Color(hex: 0xF6EFE2)
    static let card = Color(hex: 0xFBF7EF)
    static let sheet = Color(hex: 0xFFFCF5)
    static let ink = Color(hex: 0x1F2440)
    static let muted = Color(hex: 0x4A4F6A)
    static let lapis = Color(hex: 0x3047B8)
    static let saffron = Color(hex: 0xF4C75E)
    static let turquoise = Color(hex: 0x2E9E95)
    static let coral = Color(hex: 0xF2958A)
    static let coralDeep = Color(hex: 0xE0564B)
    static let coralText = Color(hex: 0xB8382E)
    static let rule = Color(hex: 0xD9CFBD)
    static let dim = Color(hex: 0x7D7A92)
    static let dimText = Color(hex: 0x6B6880)
}

/// Soft tints for the letter families.
enum Tint: String, Hashable {
    case turquoise, saffron, coral, lapis, pistachio, rose, lilac

    var color: Color {
        switch self {
        case .turquoise: return Color(hex: 0xC4E8E3)
        case .saffron: return Color(hex: 0xFBE7B5)
        case .coral: return Color(hex: 0xF9CFC8)
        case .lapis: return Color(hex: 0xD5DDFA)
        case .pistachio: return Color(hex: 0xDDEBC4)
        case .rose: return Color(hex: 0xFAD6DE)
        case .lilac: return Color(hex: 0xE4DAF3)
        }
    }
}

/// Fonts bundled in Alefba/Fonts (registered at launch by FontRegistry).
enum AppFont {
    enum Weight { case regular, semibold, bold }

    /// Fraunces SemiBold – headings.
    static func display(_ size: CGFloat) -> Font {
        .custom("Fraunces-SemiBold", fixedSize: size)
    }

    /// Figtree – interface text.
    static func body(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
        switch weight {
        case .regular: return .custom("Figtree-Regular", fixedSize: size)
        case .semibold: return .custom("Figtree-SemiBold", fixedSize: size)
        case .bold: return .custom("Figtree-Bold", fixedSize: size)
        }
    }

    /// Vazirmatn – every letter he studies or traces (round, even strokes, like handwriting).
    static func letter(_ size: CGFloat) -> Font {
        .custom("Vazirmatn-Medium", fixedSize: size)
    }

    /// IRANSans – Persian words he reads (example words, logo).
    static func farsi(_ size: CGFloat) -> Font {
        .custom("IRANSans", fixedSize: size)
    }
}

enum FontRegistry {
    /// Registers every .ttf/.otf in the app bundle so the custom fonts work
    /// without listing them in Info.plist.
    static func registerAll() {
        var urls: [URL] = []
        for ext in ["ttf", "otf"] {
            urls += Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            urls += Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") ?? []
        }
        for url in Set(urls) {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
