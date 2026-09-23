//
//  ThemeModel.swift
//  ScratchBook
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Owns the selected theme and the set of themes the user has imported.
///
/// Selecting a theme forces the app's appearance so that a light palette such as
/// Catppuccin Latte renders correctly even while the system is in Dark Mode.
/// Selecting `Theme.systemDefaultID` clears that override and returns ScratchBook
/// to following the system appearance.
final class ThemeModel: ObservableObject {
    /// The themes the user has imported, ordered by name.
    @Published private(set) var importedThemes: [Theme]

    @Published var selectedThemeID: String {
        didSet {
            guard selectedThemeID != oldValue else { return }

            ScratchBookUserDefaults.defaults.set(selectedThemeID, forKey: ScratchBookUserDefaults.themeID)
            NSApp.appearance = Self.forcedAppearance(forThemeID: selectedThemeID)
        }
    }

    /// The theme currently in effect, or `nil` when ScratchBook is following the
    /// system appearance.
    var theme: Theme? {
        guard selectedThemeID != Theme.systemDefaultID else { return nil }
        return allThemes.first { $0.id == selectedThemeID }
    }

    /// Every selectable theme, bundled and imported.
    var allThemes: [Theme] {
        BuiltInThemes.all + importedThemes
    }

    /// The selected theme when it is an imported one, which is the only case in
    /// which it can be removed.
    var importedThemeSelection: Theme? {
        importedThemes.first { $0.id == selectedThemeID }
    }

    init() {
        let loadedThemes = ThemeStorage.loadImportedThemes()
        importedThemes = loadedThemes

        let storedThemeID = ScratchBookUserDefaults.defaults.string(forKey: ScratchBookUserDefaults.themeID)
            ?? Theme.systemDefaultID
        let storedThemeExists = storedThemeID == Theme.systemDefaultID
            || BuiltInThemes.theme(withID: storedThemeID) != nil
            || loadedThemes.contains { $0.id == storedThemeID }

        // Fall back to the system default when the stored theme has disappeared,
        // which happens if an imported theme file is removed outside the app.
        selectedThemeID = storedThemeExists ? storedThemeID : Theme.systemDefaultID
    }

    /// Applies the stored appearance. Called once at launch, after the app has
    /// finished launching, because `NSApp` is not ready to be configured from
    /// within `ScratchBookApp.init()`.
    func applyStoredAppearance() {
        NSApp.appearance = Self.forcedAppearance(forThemeID: selectedThemeID)
    }

    // MARK: - Importing and removing

    /// Presents an open panel and imports the selected theme file.
    func importTheme() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.json]
        openPanel.message = String(localized: "Choose a theme file to import.")

        guard openPanel.runModal() == .OK, let url = openPanel.url else { return }

        do {
            let theme = try ThemeStorage.importTheme(from: url, existingIdentifiers: Set(allThemes.map(\.id)))
            importedThemes = ThemeStorage.loadImportedThemes()
            selectedThemeID = theme.id
        } catch {
            ErrorHandling.showErrorToUser(
                String(localized: "The theme could not be imported."),
                informativeText: error.localizedDescription
            )
        }
    }

    /// Removes an imported theme. Bundled themes cannot be removed.
    func removeTheme(_ theme: Theme) {
        guard importedThemes.contains(where: { $0.id == theme.id }) else { return }

        let alert = NSAlert()
        alert.messageText = String(localized: "Are you sure you want to remove “\(theme.name)”?")
        alert.informativeText = String(localized: "The theme will be deleted from your Mac. Your notes will not be affected.")
        alert.addButton(withTitle: String(localized: "No"))
        alert.addButton(withTitle: String(localized: "Yes"))
        alert.alertStyle = .warning
        alert.buttons.last?.hasDestructiveAction = true

        guard alert.runModal() == .alertSecondButtonReturn else { return }

        do {
            try ThemeStorage.removeTheme(theme)
            importedThemes = ThemeStorage.loadImportedThemes()

            if selectedThemeID == theme.id {
                selectedThemeID = Theme.systemDefaultID
            }
        } catch {
            ErrorHandling.showErrorToUser(
                String(localized: "The theme could not be removed."),
                informativeText: error.localizedDescription
            )
        }
    }

    // MARK: - Appearance resolution

    /// Resolves the appearance to force for a theme identifier, consulting both the
    /// bundled palettes and any themes on disk.
    ///
    /// This is static, and reads the imported themes back from disk, so that it can
    /// also be used at launch from the app delegate before a `ThemeModel` instance
    /// necessarily exists.
    static func forcedAppearance(forThemeID id: String) -> NSAppearance? {
        guard id != Theme.systemDefaultID else { return nil }

        let theme = BuiltInThemes.theme(withID: id)
            ?? ThemeStorage.loadImportedThemes().first { $0.id == id }

        return theme?.forcedAppearance
    }
}

/// Reads and writes user-imported themes.
///
/// Imported themes live in the app's Application Support directory, inside the
/// sandbox container, so no security-scoped bookmark is needed — unlike the notes
/// storage location, which can point anywhere the user chooses.
enum ThemeStorage {
    #if DEBUG
    private static let folderName = "Themes-debug"
    #else
    private static let folderName = "Themes"
    #endif

    private static var folderURL: URL? {
        guard let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
              let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return nil
        }

        return applicationSupportURL
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent(folderName, isDirectory: true)
    }

    /// Loads every theme file in the imported themes folder, skipping any that fail
    /// to decode so that a single bad file cannot keep the app from launching.
    static func loadImportedThemes() -> [Theme] {
        guard let folderURL,
              let contents = try? FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil) else {
            return []
        }

        return contents
            .filter { $0.pathExtension.lowercased() == "json" }
            .compactMap { try? decodeTheme(at: $0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Validates a theme file and copies it into the imported themes folder.
    @discardableResult
    static func importTheme(from url: URL, existingIdentifiers: Set<String>) throws -> Theme {
        let theme = try decodeTheme(at: url)

        guard !theme.id.isEmpty else { throw ThemeValidationError.invalidIdentifier }
        guard !existingIdentifiers.contains(theme.id) else {
            throw ThemeValidationError.conflictingIdentifier(theme.id)
        }
        guard let folderURL else { throw ThemeValidationError.notAThemeFile }

        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        // Re-encode on write so the stored file is clean JSON rather than whatever
        // formatting the user's file happened to have.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(theme).write(to: folderURL.appendingPathComponent("\(theme.id).json"), options: .atomic)

        return theme
    }

    static func removeTheme(_ theme: Theme) throws {
        guard let folderURL else { return }

        let url = folderURL.appendingPathComponent("\(theme.id).json")
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private static func decodeTheme(at url: URL) throws -> Theme {
        guard let data = try? Data(contentsOf: url) else {
            throw ThemeValidationError.notAThemeFile
        }

        do {
            return try JSONDecoder().decode(Theme.self, from: data)
        } catch let error as ThemeValidationError {
            // Thrown by ThemeColor or the theme's own validation, and already
            // carries a message meant for the user.
            throw error
        } catch let error as DecodingError {
            throw ThemeValidationError.from(error)
        } catch {
            throw ThemeValidationError.notAThemeFile
        }
    }
}
