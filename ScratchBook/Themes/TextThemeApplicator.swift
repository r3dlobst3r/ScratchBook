//
//  TextThemeApplicator.swift
//  ScratchBook
//

import AppKit

/// Applies theme colors to note text, and strips them back out again on the way to disk.
///
/// Kept separate from `RichTextEditor` so the two rules that protect note files — what
/// counts as body text, and what gets written to a file — can be exercised directly.
///
/// The central rule is that a theme is a *display* concern. Note files are RTFD, which
/// stores resolved colors, so a theme color reaching the file would be permanent: the
/// note would keep that one palette no matter which theme was selected later, and would
/// be invisible if the two happened to share a background. Every path into the model
/// therefore runs through `normalizedForStorage`, and every path onto the screen runs
/// through `recolor`.
enum TextThemeApplicator {
    /// Returns the color body text is drawn in for a theme, or the storage color when
    /// no theme is selected.
    private static func displayColor(for theme: Theme?) -> NSColor {
        theme?.foreground.nsColor ?? Theme.bodyTextStorageColor.nsColor
    }

    /// Redraws body text in the theme's foreground color.
    ///
    /// A run counts as body text when it carries the storage color, either of the two
    /// colors `NSColor.textColor` can resolve to, or the previous theme's foreground.
    /// Anything else is a color the user picked deliberately through the font panel or
    /// the Format menu, and is left alone so their formatting survives a theme change.
    ///
    /// Both resolved variants of the system text color are recognized because a note
    /// saved by an earlier version of ScratchBook holds whichever one was current at the
    /// time. A note saved while the system was in Dark Mode contains white, and without
    /// this it would stay white — and so be invisible — under a light theme.
    ///
    /// Passing `nil` for `theme` returns body text to the storage color, which
    /// `usesAdaptiveColorMappingForDarkAppearance` then draws correctly for the system
    /// appearance. That is how ScratchBook has always handled unthemed text.
    ///
    /// - Parameter previousTheme: The theme the text was last drawn for, if any.
    static func recolor(_ textStorage: NSMutableAttributedString, to theme: Theme?, from previousTheme: Theme?) {
        guard textStorage.length > 0 else { return }

        let newForeground = displayColor(for: theme)
        let previousForeground = previousTheme?.foreground.nsColor
        let fullRange = NSRange(location: 0, length: textStorage.length)

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.foregroundColor, in: fullRange, options: []) { value, range, _ in
            // An uncolored run falls back to the text view's own color, which would not
            // match the rest of a themed document, so give it one.
            guard let currentColor = value as? NSColor else {
                textStorage.addAttribute(.foregroundColor, value: newForeground, range: range)
                return
            }

            // Already the color this theme draws in
            guard !ThemeColor.matches(currentColor, newForeground) else { return }

            let wasPreviousThemeForeground = previousForeground.map {
                ThemeColor.matches(currentColor, $0)
            } ?? false

            let isBodyTextColor = ThemeColor.matches(currentColor, Theme.bodyTextStorageColor.nsColor)
                || ThemeColor.matches(currentColor, .textColor)
                || ThemeColor.matches(currentColor, .white)

            guard wasPreviousThemeForeground || isBodyTextColor else { return }

            textStorage.addAttribute(.foregroundColor, value: newForeground, range: range)
        }
        textStorage.endEditing()
    }

    /// Rewrites the theme's display color back to the fixed storage color.
    ///
    /// Called before text reaches the model, so neither the in-memory contents nor the
    /// RTFD file on disk ever holds a theme color.
    static func normalizedForStorage(_ attributedString: NSAttributedString, theme: Theme?) -> NSAttributedString {
        guard let themeForeground = theme?.foreground.nsColor else { return attributedString }

        let normalized = NSMutableAttributedString(attributedString: attributedString)
        guard normalized.length > 0 else { return normalized }

        let fullRange = NSRange(location: 0, length: normalized.length)

        normalized.beginEditing()
        normalized.enumerateAttribute(.foregroundColor, in: fullRange, options: []) { value, range, _ in
            guard let currentColor = value as? NSColor,
                  ThemeColor.matches(currentColor, themeForeground) else { return }

            normalized.addAttribute(.foregroundColor, value: Theme.bodyTextStorageColor.nsColor, range: range)
        }
        normalized.endEditing()

        return normalized
    }
}
