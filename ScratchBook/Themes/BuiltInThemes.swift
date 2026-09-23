//
//  BuiltInThemes.swift
//  ScratchBook
//

import Foundation

/// The themes that ship with ScratchBook.
///
/// Every color below is taken from the upstream project's own published palette
/// rather than being approximated by eye. See `THIRD_PARTY_LICENSES.md` for the
/// attribution and license of each palette.
enum BuiltInThemes {
    static let all: [Theme] = [
        catppuccinMocha,
        catppuccinMacchiato,
        catppuccinFrappe,
        catppuccinLatte,
        dracula,
        nord,
        gruvboxDark,
        gruvboxLight,
        tokyoNight,
        tokyoNightLight,
        solarizedDark,
        solarizedLight,
        oneDark,
        oneLight,
        rosePineMain,
        rosePineMoon,
        rosePineDawn,
        everforestDark,
        everforestLight,
        kanagawa
    ]

    /// Looks up a bundled theme by its identifier.
    static func theme(withID id: String) -> Theme? {
        all.first { $0.id == id }
    }

    // MARK: - Catppuccin
    // https://github.com/catppuccin/palette
    // Colors: base, text, mauve, surface0, rosewater.

    static let catppuccinMocha = Theme(
        id: "catppuccin-mocha",
        name: "Catppuccin Mocha",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#1e1e2e"),
        foreground: ThemeColor(hexOrFallback: "#cdd6f4"),
        accent: ThemeColor(hexOrFallback: "#cba6f7"),
        selection: ThemeColor(hexOrFallback: "#313244"),
        caret: ThemeColor(hexOrFallback: "#f5e0dc")
    )

    static let catppuccinMacchiato = Theme(
        id: "catppuccin-macchiato",
        name: "Catppuccin Macchiato",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#24273a"),
        foreground: ThemeColor(hexOrFallback: "#cad3f5"),
        accent: ThemeColor(hexOrFallback: "#c6a0f6"),
        selection: ThemeColor(hexOrFallback: "#363a4f"),
        caret: ThemeColor(hexOrFallback: "#f4dbd6")
    )

    static let catppuccinFrappe = Theme(
        id: "catppuccin-frappe",
        name: "Catppuccin Frappé",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#303446"),
        foreground: ThemeColor(hexOrFallback: "#c6d0f5"),
        accent: ThemeColor(hexOrFallback: "#ca9ee6"),
        selection: ThemeColor(hexOrFallback: "#414559"),
        caret: ThemeColor(hexOrFallback: "#f2d5cf")
    )

    static let catppuccinLatte = Theme(
        id: "catppuccin-latte",
        name: "Catppuccin Latte",
        appearance: .light,
        background: ThemeColor(hexOrFallback: "#eff1f5"),
        foreground: ThemeColor(hexOrFallback: "#4c4f69"),
        accent: ThemeColor(hexOrFallback: "#8839ef"),
        selection: ThemeColor(hexOrFallback: "#ccd0da"),
        caret: ThemeColor(hexOrFallback: "#dc8a78")
    )

    // MARK: - Dracula
    // https://github.com/dracula/dracula-theme

    static let dracula = Theme(
        id: "dracula",
        name: "Dracula",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#282a36"),
        foreground: ThemeColor(hexOrFallback: "#f8f8f2"),
        accent: ThemeColor(hexOrFallback: "#bd93f9"),
        selection: ThemeColor(hexOrFallback: "#44475a"),
        caret: ThemeColor(hexOrFallback: "#ff79c6")
    )

    // MARK: - Nord
    // https://www.nordtheme.com/docs/colors-and-palettes
    // Colors: nord0, nord4, nord8, nord2, nord7.

    static let nord = Theme(
        id: "nord",
        name: "Nord",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#2e3440"),
        foreground: ThemeColor(hexOrFallback: "#d8dee9"),
        accent: ThemeColor(hexOrFallback: "#88c0d0"),
        selection: ThemeColor(hexOrFallback: "#434c5e"),
        caret: ThemeColor(hexOrFallback: "#8fbcbb")
    )

    // MARK: - Gruvbox
    // https://github.com/morhetz/gruvbox

    static let gruvboxDark = Theme(
        id: "gruvbox-dark",
        name: "Gruvbox Dark",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#282828"),
        foreground: ThemeColor(hexOrFallback: "#ebdbb2"),
        accent: ThemeColor(hexOrFallback: "#fe8019"),
        selection: ThemeColor(hexOrFallback: "#504945"),
        caret: ThemeColor(hexOrFallback: "#d5c4a1")
    )

    static let gruvboxLight = Theme(
        id: "gruvbox-light",
        name: "Gruvbox Light",
        appearance: .light,
        background: ThemeColor(hexOrFallback: "#fbf1c7"),
        foreground: ThemeColor(hexOrFallback: "#3c3836"),
        accent: ThemeColor(hexOrFallback: "#af3a03"),
        selection: ThemeColor(hexOrFallback: "#d5c4a1"),
        caret: ThemeColor(hexOrFallback: "#665c54")
    )

    // MARK: - Tokyo Night
    // https://github.com/enkia/tokyo-night-vscode-theme
    // The upstream selection colors carry an alpha channel; the opaque base color
    // is used here since `ThemeColor` is fully opaque.

    static let tokyoNight = Theme(
        id: "tokyo-night",
        name: "Tokyo Night",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#1a1b26"),
        foreground: ThemeColor(hexOrFallback: "#a9b1d6"),
        accent: ThemeColor(hexOrFallback: "#7aa2f7"),
        selection: ThemeColor(hexOrFallback: "#515c7e"),
        caret: ThemeColor(hexOrFallback: "#c0caf5")
    )

    static let tokyoNightLight = Theme(
        id: "tokyo-night-light",
        name: "Tokyo Night Light",
        appearance: .light,
        background: ThemeColor(hexOrFallback: "#e6e7ed"),
        foreground: ThemeColor(hexOrFallback: "#343b59"),
        accent: ThemeColor(hexOrFallback: "#2959aa"),
        selection: ThemeColor(hexOrFallback: "#acb0bf"),
        caret: ThemeColor(hexOrFallback: "#363c4d")
    )

    // MARK: - Solarized
    // https://ethanschoonover.com/solarized/

    static let solarizedDark = Theme(
        id: "solarized-dark",
        name: "Solarized Dark",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#002b36"),
        foreground: ThemeColor(hexOrFallback: "#839496"),
        accent: ThemeColor(hexOrFallback: "#268bd2"),
        selection: ThemeColor(hexOrFallback: "#073642"),
        caret: ThemeColor(hexOrFallback: "#93a1a1")
    )

    static let solarizedLight = Theme(
        id: "solarized-light",
        name: "Solarized Light",
        appearance: .light,
        background: ThemeColor(hexOrFallback: "#fdf6e3"),
        foreground: ThemeColor(hexOrFallback: "#657b83"),
        accent: ThemeColor(hexOrFallback: "#268bd2"),
        selection: ThemeColor(hexOrFallback: "#eee8d5"),
        caret: ThemeColor(hexOrFallback: "#586e75")
    )

    // MARK: - One
    // https://github.com/atom/one-dark-syntax and https://github.com/atom/one-light-syntax

    static let oneDark = Theme(
        id: "one-dark",
        name: "One Dark",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#282c34"),
        foreground: ThemeColor(hexOrFallback: "#abb2bf"),
        accent: ThemeColor(hexOrFallback: "#61afef"),
        selection: ThemeColor(hexOrFallback: "#3e4452"),
        caret: ThemeColor(hexOrFallback: "#528bff")
    )

    static let oneLight = Theme(
        id: "one-light",
        name: "One Light",
        appearance: .light,
        background: ThemeColor(hexOrFallback: "#fafafa"),
        foreground: ThemeColor(hexOrFallback: "#383a42"),
        accent: ThemeColor(hexOrFallback: "#4078f2"),
        selection: ThemeColor(hexOrFallback: "#e5e5e6"),
        caret: ThemeColor(hexOrFallback: "#526fff")
    )

    // MARK: - Rosé Pine
    // https://github.com/rose-pine/palette

    static let rosePineMain = Theme(
        id: "rose-pine",
        name: "Rosé Pine",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#191724"),
        foreground: ThemeColor(hexOrFallback: "#e0def4"),
        accent: ThemeColor(hexOrFallback: "#c4a7e7"),
        selection: ThemeColor(hexOrFallback: "#26233a"),
        caret: ThemeColor(hexOrFallback: "#ebbcba")
    )

    static let rosePineMoon = Theme(
        id: "rose-pine-moon",
        name: "Rosé Pine Moon",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#232136"),
        foreground: ThemeColor(hexOrFallback: "#e0def4"),
        accent: ThemeColor(hexOrFallback: "#c4a7e7"),
        selection: ThemeColor(hexOrFallback: "#393552"),
        caret: ThemeColor(hexOrFallback: "#ea9a97")
    )

    static let rosePineDawn = Theme(
        id: "rose-pine-dawn",
        name: "Rosé Pine Dawn",
        appearance: .light,
        background: ThemeColor(hexOrFallback: "#faf4ed"),
        foreground: ThemeColor(hexOrFallback: "#464261"),
        accent: ThemeColor(hexOrFallback: "#907aa9"),
        selection: ThemeColor(hexOrFallback: "#f2e9e1"),
        caret: ThemeColor(hexOrFallback: "#d7827e")
    )

    // MARK: - Everforest
    // https://github.com/sainnhe/everforest
    // `bg_visual` is the upstream selection color.

    static let everforestDark = Theme(
        id: "everforest-dark",
        name: "Everforest Dark",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#2d353b"),
        foreground: ThemeColor(hexOrFallback: "#d3c6aa"),
        accent: ThemeColor(hexOrFallback: "#a7c080"),
        selection: ThemeColor(hexOrFallback: "#543a48"),
        caret: ThemeColor(hexOrFallback: "#e69875")
    )

    static let everforestLight = Theme(
        id: "everforest-light",
        name: "Everforest Light",
        appearance: .light,
        background: ThemeColor(hexOrFallback: "#fdf6e3"),
        foreground: ThemeColor(hexOrFallback: "#5c6a72"),
        accent: ThemeColor(hexOrFallback: "#8da101"),
        selection: ThemeColor(hexOrFallback: "#eaedc8"),
        caret: ThemeColor(hexOrFallback: "#f57d26")
    )

    // MARK: - Kanagawa
    // https://github.com/rebelot/kanagawa.nvim
    // Colors: sumiInk3, fujiWhite, crystalBlue, waveBlue2, roninYellow.

    static let kanagawa = Theme(
        id: "kanagawa",
        name: "Kanagawa",
        appearance: .dark,
        background: ThemeColor(hexOrFallback: "#1f1f28"),
        foreground: ThemeColor(hexOrFallback: "#dcd7ba"),
        accent: ThemeColor(hexOrFallback: "#7e9cd8"),
        selection: ThemeColor(hexOrFallback: "#2d4f67"),
        caret: ThemeColor(hexOrFallback: "#ff9e3b")
    )
}

private extension ThemeColor {
    /// Convenience for the bundled palettes, whose values are compile-time constants
    /// taken directly from the upstream projects and so cannot fail to parse.
    ///
    /// The fallback keeps a typo from crashing the app at launch: a malformed value
    /// degrades to mid-grey rather than trapping. Imported themes are not built this
    /// way — they are validated and decode through the throwing initializer above.
    init(hexOrFallback hex: String) {
        do {
            try self.init(hex: hex)
        } catch {
            assertionFailure("Built-in theme color \(hex) is not a valid hex string")
            self.init(red: 0.5, green: 0.5, blue: 0.5)
        }
    }
}
