//
//  Theme.swift
//  ScratchBook
//

import AppKit
import SwiftUI

/// Whether a theme is designed for a light or a dark appearance.
///
/// Selecting a theme forces the window appearance to match, so that a light
/// palette such as Catppuccin Latte still renders correctly while the system
/// itself is in Dark Mode.
enum ThemeAppearance: String, Codable {
    case light
    case dark
}

/// A single color in a theme, stored as sRGB components.
///
/// Colors are deliberately fixed rather than dynamic: a theme describes an exact
/// palette and must not shift underneath the user when the system appearance
/// changes. Values are decoded from and encoded to CSS-style hex strings
/// (`"#rrggbb"`, or the three-digit `"#rgb"` shorthand).
struct ThemeColor: Codable, Hashable {
    let red: Double
    let green: Double
    let blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(hex: String) throws {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }

        // Expand the three-digit shorthand ("#abc" becomes "#aabbcc")
        if cleaned.count == 3 {
            cleaned = cleaned.map { "\($0)\($0)" }.joined()
        }

        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            throw ThemeValidationError.invalidColor(hex)
        }

        red = Double((value & 0xFF0000) >> 16) / 255
        green = Double((value & 0x00FF00) >> 8) / 255
        blue = Double(value & 0x0000FF) / 255
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(hex: try container.decode(String.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hexString)
    }

    var hexString: String {
        String(
            format: "#%02x%02x%02x",
            Int((red * 255).rounded()),
            Int((green * 255).rounded()),
            Int((blue * 255).rounded())
        )
    }

    /// A fixed sRGB color that does not vary with the current appearance.
    var nsColor: NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }

    /// The WCAG contrast ratio between two colors, from 1 (identical) to 21 (black
    /// against white). Body text is generally expected to reach 4.5.
    static func contrast(_ lhs: ThemeColor, _ rhs: ThemeColor) -> Double {
        let a = lhs.relativeLuminance
        let b = rhs.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// The contrast below which two colors read as too close together to distinguish,
    /// used when choosing which color to draw text in over a given background.
    ///
    /// This is deliberately below the 4.5 that body text is held to, because the
    /// alternative in these cases is a hard inversion, and text slightly under the
    /// threshold still reads far better than text that nearly matches its background.
    static let readableContrast = 3.0

    /// The relative luminance defined by WCAG, used to compute contrast ratios.
    private var relativeLuminance: Double {
        // sRGB components are stored linearly, but luminance is defined over
        // linearized values.
        func linearized(_ component: Double) -> Double {
            component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
    }

    /// Compares two colors by their sRGB components.
    ///
    /// `NSColor.isEqual` is unreliable here because the same visual color can be
    /// represented in different color spaces — an `NSColor.textColor` catalog color
    /// versus an sRGB color built from a hex string — so both sides are converted to
    /// sRGB before being compared.
    static func matches(_ lhs: NSColor, _ rhs: NSColor, tolerance: Double = 0.001) -> Bool {
        guard let a = lhs.usingColorSpace(.sRGB), let b = rhs.usingColorSpace(.sRGB) else {
            return lhs.isEqual(rhs)
        }

        return abs(a.redComponent - b.redComponent) < tolerance
            && abs(a.greenComponent - b.greenComponent) < tolerance
            && abs(a.blueComponent - b.blueComponent) < tolerance
    }
}

/// A complete color scheme for ScratchBook.
struct Theme: Codable, Identifiable, Hashable {
    /// The identifier used to persist the user's selection.
    let id: String
    /// The name shown in the theme picker.
    let name: String
    let appearance: ThemeAppearance
    /// The page background drawn behind the note text.
    let background: ThemeColor
    /// The default body text color.
    let foreground: ThemeColor
    /// The tint applied to controls and toolbar items.
    let accent: ThemeColor
    /// The text selection highlight.
    let selection: ThemeColor
    /// The insertion point.
    let caret: ThemeColor

    /// The appearance to force while this theme is active.
    var forcedAppearance: NSAppearance? {
        NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
    }

    /// The color to draw selected text in when this theme is active.
    ///
    /// Normally the theme's own foreground. That is not safe in general, though, since
    /// nothing stops a palette — especially an imported one — from pairing a selection
    /// color with a foreground that sits too close to it, which would make selected
    /// text nearly unreadable. When the foreground does not stand out against the
    /// selection, the background color is used as the text color instead, which reads
    /// as a simple inverted highlight.
    ///
    /// This picks a readable text color rather than altering `selection`, so the
    /// palette values themselves stay faithful to the upstream project.
    var selectionTextColor: ThemeColor {
        ThemeColor.contrast(foreground, selection) >= ThemeColor.readableContrast
            ? foreground
            : background
    }

    /// The identifier reported when no theme is selected and ScratchBook follows
    /// the system appearance instead.
    static let systemDefaultID = "system-default"

    /// The color ScratchBook writes into note files for body text.
    ///
    /// Deliberately a fixed color rather than `NSColor.textColor`. The system text color
    /// resolves to black or white according to whichever appearance is in effect at the
    /// moment a note is saved, and RTFD stores that resolved value rather than the
    /// dynamic color. A note saved while a dark theme was active would therefore end up
    /// with white baked into the file, and would render invisibly under a light theme or
    /// a light system appearance. Storing a fixed color keeps note files
    /// appearance-independent; the display layer decides what to draw.
    static let bodyTextStorageColor = ThemeColor(red: 0, green: 0, blue: 0)
}

/// Errors raised while reading or validating a theme, all of which are surfaced to
/// the user with a readable explanation.
enum ThemeValidationError: LocalizedError {
    case invalidColor(String)
    case invalidAppearance
    case missingField(String)
    case invalidIdentifier
    case conflictingIdentifier(String)
    case notAThemeFile

    var errorDescription: String? {
        switch self {
        case .invalidColor(let value):
            return String(localized: "\(value) is not a valid hex color. Colors must be written as #rrggbb.")
        case .invalidAppearance:
            return String(localized: "The appearance value must be either light or dark.")
        case .missingField(let field):
            return String(localized: "The theme is missing the required \(field) field.")
        case .invalidIdentifier:
            return String(localized: "The theme needs a non-empty id field.")
        case .conflictingIdentifier(let id):
            return String(localized: "A theme with the identifier \(id) already exists.")
        case .notAThemeFile:
            return String(localized: "The selected file is not a valid theme file.")
        }
    }

    /// Converts a decoding failure into a message that describes what is wrong with
    /// the theme file rather than how `Codable` failed to read it.
    static func from(_ error: DecodingError) -> ThemeValidationError {
        switch error {
        case .keyNotFound(let key, _):
            return .missingField(key.stringValue)
        case .dataCorrupted(let context):
            // An unrecognized appearance value lands here, because ThemeAppearance
            // decodes from a raw string.
            return context.codingPath.last?.stringValue == "appearance" ? .invalidAppearance : .notAThemeFile
        case .typeMismatch(_, let context), .valueNotFound(_, let context):
            return .missingField(context.codingPath.last?.stringValue ?? String(localized: "unknown"))
        @unknown default:
            return .notAThemeFile
        }
    }
}
