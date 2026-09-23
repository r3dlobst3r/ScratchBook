//
//  ThemePicker.swift
//  ScratchBook
//

import SwiftUI

/// The theme row in the Settings window: a picker over the bundled and imported
/// themes, a preview of the current palette, and buttons to import or remove a theme.
struct ThemePicker: View {
    @EnvironmentObject private var themeModel: ThemeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("", selection: $themeModel.selectedThemeID) {
                Text("System Default", comment: "Theme picker entry that follows the macOS appearance")
                    .tag(Theme.systemDefaultID)

                Section(String(localized: "Built-in")) {
                    ForEach(BuiltInThemes.all) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }

                if !themeModel.importedThemes.isEmpty {
                    Section(String(localized: "Imported")) {
                        ForEach(themeModel.importedThemes) { theme in
                            Text(theme.name).tag(theme.id)
                        }
                    }
                }
            }
            .labelsHidden()
            .frame(maxWidth: 240)

            HStack(spacing: 15) {
                ThemePreview(theme: themeModel.theme)

                Spacer()

                Button("Import Theme...") {
                    themeModel.importTheme()
                }

                Button("Remove") {
                    if let importedTheme = themeModel.importedThemeSelection {
                        themeModel.removeTheme(importedTheme)
                    }
                }
                .disabled(themeModel.importedThemeSelection == nil)
            }
        }
    }
}

/// A small row of swatches showing the colors of a theme, or a note that the app is
/// following the system appearance when no theme is selected.
private struct ThemePreview: View {
    let theme: Theme?

    var body: some View {
        HStack(spacing: 4) {
            if let theme = theme {
                swatch(theme.background)
                swatch(theme.foreground)
                swatch(theme.accent)
                swatch(theme.selection)
                swatch(theme.caret)
            } else {
                Text("Follows the system appearance")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func swatch(_ color: ThemeColor) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color.color)
            .frame(width: 16, height: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color.primary.opacity(0.2))
            )
    }
}

/// Applies a theme to the window toolbar. When no theme is selected the toolbar
/// keeps its standard system appearance.
///
/// Note that on current versions of macOS the window toolbar is a system material,
/// so this tints it rather than replacing it with a flat theme-colored bar.
struct ThemedWindowToolbar: ViewModifier {
    let theme: Theme?

    func body(content: Content) -> some View {
        if let theme = theme {
            content
                .toolbarBackground(theme.background.color, for: .windowToolbar)
                .toolbarColorScheme(theme.appearance == .dark ? .dark : .light, for: .windowToolbar)
        } else {
            content
        }
    }
}

extension View {
    func themedWindowToolbar(_ theme: Theme?) -> some View {
        modifier(ThemedWindowToolbar(theme: theme))
    }
}
