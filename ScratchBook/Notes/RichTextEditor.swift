//
//  RichTextEditor.swift
//  ScratchPad
//
//  Created by Alex Seifert on 09.12.22.
//

import SwiftUI

private class ScratchBookTextView: NSTextView {
    /// The foreground color the active theme draws body text in, or `nil` when
    /// ScratchBook is following the system appearance.
    ///
    /// Reset formatting writes the system text color into the model — themes are a
    /// display concern and must not be persisted — but the text should still be drawn
    /// in the theme color, so the view needs to know what that is.
    var themeForeground: NSColor?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == [.command, .shift, .option],
           event.charactersIgnoringModifiers?.lowercased() == "v" {
            pasteAsPlainText(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    @objc func resetFormatting(_ sender: Any?) {
        guard let textStorage = textStorage else { return }
        let range = selectedRange().length > 0 ? selectedRange() : NSRange(location: 0, length: textStorage.length)
        guard range.length > 0 else { return }

        let defaultFont = NSFont.userFont(ofSize: NSFont.systemFontSize) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: defaultFont,
            .foregroundColor: themeForeground ?? NSColor.textColor,
            .paragraphStyle: NSParagraphStyle.default
        ]

        if shouldChangeText(in: range, replacementString: nil) {
            textStorage.beginEditing()
            textStorage.setAttributes(defaultAttributes, range: range)
            textStorage.endEditing()
            didChangeText()
        }
    }
}

struct RichTextEditor: NSViewRepresentable {
    @EnvironmentObject var noteModel: NoteModel
    @EnvironmentObject var themeModel: ThemeModel

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = ScratchBookTextView.scrollableTextView()

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.isRichText = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.allowsImageEditing = true
        textView.allowsDocumentBackgroundColorChange = true
        textView.allowsCharacterPickerTouchBarItem = true
        textView.isAutomaticLinkDetectionEnabled = true
        textView.displaysLinkToolTips = true
        textView.isAutomaticDataDetectionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticTextCompletionEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.usesInspectorBar = true
        textView.usesRuler = true
        textView.usesFindBar = true
        textView.usesFontPanel = true
        textView.importsGraphics = true

        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        applyTheme(to: textView, coordinator: context.coordinator)
        context.coordinator.loadedContents = noteModel.noteContents

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        // Skip update if the change came from the textView itself
        if context.coordinator.isUpdatingFromTextView {
            context.coordinator.isUpdatingFromTextView = false
            return
        }

        applyTheme(to: textView, coordinator: context.coordinator)

        // Reload only when the model's contents actually changed, which means the page
        // was switched or the note was re-read from disk. Comparing against the
        // coordinator's snapshot rather than the text view's own string is deliberate:
        // the text view is always recolored for the active theme, so it would otherwise
        // never compare equal and every update would clobber the selection and undo
        // stack.
        guard context.coordinator.loadedContents != noteModel.noteContents else { return }

        let nsAttributedString = (try? NSAttributedString(noteModel.noteContents, including: \.appKit))
            ?? NSAttributedString(noteModel.noteContents)
        textView.textStorage?.setAttributedString(nsAttributedString)
        context.coordinator.loadedContents = noteModel.noteContents

        // The freshly loaded runs carry the storage color, so they need the theme
        // applied before they are shown.
        if let textStorage = textView.textStorage {
            TextThemeApplicator.recolor(textStorage, to: themeModel.theme, from: nil)
        }
    }

    /// Applies the active theme's colors to the text view.
    private func applyTheme(to textView: NSTextView, coordinator: Coordinator) {
        let theme = themeModel.theme
        let previousTheme = coordinator.appliedTheme
        let themeChanged = previousTheme?.id != theme?.id
        coordinator.appliedTheme = theme

        // Adaptive color mapping remaps the exact palette colors to the system
        // appearance, which defeats the point of a fixed theme, so it is only left on
        // while no theme is selected.
        textView.usesAdaptiveColorMappingForDarkAppearance = theme == nil

        (textView as? ScratchBookTextView)?.themeForeground = theme?.foreground.nsColor

        textView.backgroundColor = theme?.background.nsColor ?? .textBackgroundColor
        textView.insertionPointColor = theme?.caret.nsColor ?? .textColor
        textView.selectedTextAttributes = [
            .backgroundColor: theme?.selection.nsColor ?? NSColor.selectedTextBackgroundColor,
            .foregroundColor: theme?.selectionTextColor.nsColor ?? NSColor.selectedTextColor
        ]

        // Newly typed text has to pick up the theme color explicitly, otherwise it would
        // be drawn in the system text color on top of a themed background.
        let font = (textView.typingAttributes[.font] as? NSFont)
            ?? NSFont.userFont(ofSize: NSFont.systemFontSize)
            ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: theme?.foreground.nsColor ?? NSColor.textColor
        ]

        if themeChanged, let textStorage = textView.textStorage {
            TextThemeApplicator.recolor(textStorage, to: theme, from: previousTheme)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        var textView: NSTextView?
        var isUpdatingFromTextView = false
        /// The theme currently applied to the text view. `nil` means the system default.
        var appliedTheme: Theme?
        /// The contents the text view was last loaded from, used to tell a genuine
        /// content change apart from a theme change.
        var loadedContents: AttributedString?

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isUpdatingFromTextView = true

            let attributed = TextThemeApplicator.normalizedForStorage(
                textView.attributedString(),
                theme: parent.themeModel.theme
            )
            let contents = (try? AttributedString(attributed, including: \.appKit))
                ?? AttributedString(attributed)

            loadedContents = contents
            parent.noteModel.noteContents = contents
        }
    }
}
