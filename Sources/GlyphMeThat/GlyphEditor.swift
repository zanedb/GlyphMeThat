import UIKit
import SwiftUI

/// A SwiftUI wrapper around `UITextView` providing adaptive image glyph support for attributed text.
///
/// Wraps `UITextView` to allow insertion of `NSAdaptiveImageGlyph` (iOS 18+).
/// Use modifiers to configure placeholder, character limit, styling, and focus control.
public struct GlyphEditor: UIViewRepresentable {
    @Binding public var attributedText: NSAttributedString

    // Struct-level configuration
    public var placeholder: String?
    public var characterLimit: Int?
    public var textAlignment: NSTextAlignment?
    public var allowsEditingTextAttributes: Bool?
    public var supportsAdaptiveImageGlyph: Bool?
    public var font: UIFont?

    public init(attributedText: Binding<NSAttributedString>) {
        self._attributedText = attributedText
        self.placeholder = nil
        self.characterLimit = nil
        self.textAlignment = nil
        self.allowsEditingTextAttributes = nil
        self.supportsAdaptiveImageGlyph = nil
        self.font = nil
    }

    // Chainable modifiers
    public func placeholder(_ placeholder: String) -> Self { var copy = self; copy.placeholder = placeholder; return copy }
    public func characterLimit(_ limit: Int) -> Self { var copy = self; copy.characterLimit = limit; return copy }
    public func textAlignment(_ alignment: NSTextAlignment) -> Self { var copy = self; copy.textAlignment = alignment; return copy }
    public func allowsEditingTextAttributes(_ allows: Bool) -> Self { var copy = self; copy.allowsEditingTextAttributes = allows; return copy }
    public func supportsAdaptiveImageGlyph(_ supports: Bool) -> Self { var copy = self; copy.supportsAdaptiveImageGlyph = supports; return copy }
    public func font(_ font: UIFont) -> Self { var copy = self; copy.font = font; return copy }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UITextView {
        let env = context.environment
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = env._glyphTextEditorFont.map(UIFont.init) ?? .systemFont(ofSize: UIFont.systemFontSize)
        textView.textAlignment = env._glyphTextEditorTextAlignment ?? .natural
        textView.allowsEditingTextAttributes = env._glyphTextEditorAllowsEditingTextAttributes ?? false
        textView.supportsAdaptiveImageGlyph = env._glyphTextEditorSupportsAdaptiveImageGlyph ?? true
        textView.attributedText = attributedText
        textView.backgroundColor = .clear
        // placeholder label
        if let placeholder = env._glyphTextEditorPlaceholder ?? self.placeholder {
            let label = UILabel()
            label.text = placeholder
            label.font = textView.font
            label.textColor = UIColor.placeholderText
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            textView.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: textView.layoutMarginsGuide.leadingAnchor),
                label.topAnchor.constraint(equalTo: textView.layoutMarginsGuide.topAnchor)
            ])
            context.coordinator.placeholderLabel = label
            label.isHidden = !(textView.text?.isEmpty ?? true)
        }
        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        let env = context.environment
        // Block binding updates during UI sync
        context.coordinator.isApplyingCoordinatorUpdate = true

        // Configuration: struct-level overrides or environment fallback
        let swiftFont: Font = self.font.map(Font.init) ?? env._glyphTextEditorFont ?? env.font ?? .body
        let uiFont = self.font ?? UIFont(swiftFont)
        let limit = env._glyphTextEditorCharacterLimit ?? self.characterLimit
        // update stored values for Coordinator (reference type, mutable)
        context.coordinator.currentFont = uiFont
        context.coordinator.currentCharacterLimit = limit
        uiView.font = uiFont
        // update placeholder text and font
        context.coordinator.placeholderLabel?.text = self.placeholder ?? env._glyphTextEditorPlaceholder
        context.coordinator.placeholderLabel?.font = uiFont
        uiView.textAlignment = env._glyphTextEditorTextAlignment ?? self.textAlignment ?? .natural
        uiView.allowsEditingTextAttributes = env._glyphTextEditorAllowsEditingTextAttributes ?? self.allowsEditingTextAttributes ?? false
        uiView.supportsAdaptiveImageGlyph = env._glyphTextEditorSupportsAdaptiveImageGlyph ?? self.supportsAdaptiveImageGlyph ?? true
        // sync text
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
        }
        // focus handling: only change when state actually changes
        let focusNow = env.isFocused
        let coord = context.coordinator
        if focusNow && !coord.isCurrentlyFocused {
            uiView.becomeFirstResponder()
        } else if !focusNow && coord.isCurrentlyFocused {
            uiView.resignFirstResponder()
        }
        coord.isCurrentlyFocused = focusNow
        // placeholder
        if let label = context.coordinator.placeholderLabel {
            label.isHidden = !(uiView.text?.isEmpty ?? true)
        }
        // enforce character limit UI
        if let limit = limit, uiView.text.count > limit {
            let truncated = String(uiView.text.prefix(limit))
            uiView.text = truncated
        }
        // Unblock binding updates after sync
        DispatchQueue.main.async {
            context.coordinator.isApplyingCoordinatorUpdate = false
        }
    }

    @MainActor public func glyphEditorStyle<S: GlyphEditorStyle>(_ style: S) -> some View {
        GlyphEditorStyleView(content: self, style: style)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        /// When true, skip binding updates during programmatic UI sync
        var isApplyingCoordinatorUpdate: Bool = false

        var parent: GlyphEditor
        weak var placeholderLabel: UILabel?
        var currentCharacterLimit: Int?
        var currentFont: UIFont?
        // Track focus to avoid unnecessary resigns
        var isCurrentlyFocused: Bool = false

        init(_ parent: GlyphEditor) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            // Determine new attributed text (apply truncation if needed)
            let currentText = textView.text ?? ""
            let newAttrText: NSAttributedString
            if let limit = currentCharacterLimit, currentText.count > limit {
                let truncated = String(currentText.prefix(limit))
                textView.text = truncated
                newAttrText = NSAttributedString(string: truncated)
            } else {
                newAttrText = textView.attributedText
            }
            placeholderLabel?.isHidden = !textView.text.isEmpty
            // Update binding asynchronously (skip if during UI sync)
            if !isApplyingCoordinatorUpdate {
                DispatchQueue.main.async {
                    self.parent.attributedText = newAttrText
                }
            }
        }

        public func textView(_ textView: UITextView,
                              shouldChangeTextIn range: NSRange,
                              replacementText text: String) -> Bool {
            guard let limit = currentCharacterLimit else {
                return true
            }
            let current = textView.text ?? ""
            guard let textRange = Range(range, in: current) else { return false }
            let updated = current.replacingCharacters(in: textRange, with: text)
            return updated.count <= limit
        }
    }
}

public extension View {
    /// Sets the placeholder text displayed when the editor is empty.
    func glyphEditorPlaceholder(_ placeholder: String) -> some View {
        environment(\._glyphTextEditorPlaceholder, placeholder)
    }
    /// Sets the maximum number of characters allowed.
    func glyphEditorCharacterLimit(_ limit: Int) -> some View {
        environment(\._glyphTextEditorCharacterLimit, limit)
    }
    /// Sets the text alignment.
    func glyphEditorTextAlignment(_ alignment: NSTextAlignment) -> some View {
        environment(\._glyphTextEditorTextAlignment, alignment)
    }
    /// Enables or disables editing of text attributes.
    func glyphEditorAllowsEditingTextAttributes(_ allows: Bool) -> some View {
        environment(\._glyphTextEditorAllowsEditingTextAttributes, allows)
    }
    /// Enables or disables support for adaptive image glyphs.
    func glyphEditorSupportsAdaptiveImageGlyph(_ supports: Bool) -> some View {
        environment(\._glyphTextEditorSupportsAdaptiveImageGlyph, supports)
    }
}

// EnvironmentKeys
private struct GlyphTextEditorPlaceholderKey: EnvironmentKey { static let defaultValue: String? = nil }
private struct GlyphTextEditorCharacterLimitKey: EnvironmentKey { static let defaultValue: Int? = nil }
private struct GlyphTextEditorTextAlignmentKey: EnvironmentKey { static let defaultValue: NSTextAlignment? = nil }
private struct GlyphTextEditorAllowsEditingTextAttributesKey: EnvironmentKey { static let defaultValue: Bool? = nil }
private struct GlyphTextEditorSupportsAdaptiveImageGlyphKey: EnvironmentKey { static let defaultValue: Bool? = nil }

private extension EnvironmentValues {
    var _glyphTextEditorPlaceholder: String? {
        get { self[GlyphTextEditorPlaceholderKey.self] }
        set { self[GlyphTextEditorPlaceholderKey.self] = newValue }
    }
    var _glyphTextEditorCharacterLimit: Int? {
        get { self[GlyphTextEditorCharacterLimitKey.self] }
        set { self[GlyphTextEditorCharacterLimitKey.self] = newValue }
    }
    var _glyphTextEditorTextAlignment: NSTextAlignment? {
        get { self[GlyphTextEditorTextAlignmentKey.self] }
        set { self[GlyphTextEditorTextAlignmentKey.self] = newValue }
    }
    var _glyphTextEditorAllowsEditingTextAttributes: Bool? {
        get { self[GlyphTextEditorAllowsEditingTextAttributesKey.self] }
        set { self[GlyphTextEditorAllowsEditingTextAttributesKey.self] = newValue }
    }
    var _glyphTextEditorSupportsAdaptiveImageGlyph: Bool? {
        get { self[GlyphTextEditorSupportsAdaptiveImageGlyphKey.self] }
        set { self[GlyphTextEditorSupportsAdaptiveImageGlyphKey.self] = newValue }
    }
}

private struct GlyphTextEditorFontKey: EnvironmentKey {
    static let defaultValue: Font? = nil
}

private extension EnvironmentValues {
    var _glyphTextEditorFont: Font? {
        get { self[GlyphTextEditorFontKey.self] }
        set { self[GlyphTextEditorFontKey.self] = newValue }
    }
}

// MARK: - GlyphEditor Style Support

/// Configuration passed to a `GlyphEditorStyle` to wrap a `GlyphEditor`.
public struct GlyphEditorStyleConfiguration {
    public let content: GlyphEditor
}

/// A style that wraps a `GlyphEditor` view.
@MainActor public protocol GlyphEditorStyle {
    /// The type of view returned by `makeBody`.
    associatedtype Body: View
    /// Builds a styled view given the configuration.
    @MainActor func makeBody(configuration: GlyphEditorStyleConfiguration) -> Body
}

@MainActor private struct GlyphEditorStyleView<Style: GlyphEditorStyle>: View {
    let content: GlyphEditor
    let style: Style
    var body: some View {
        style.makeBody(configuration: GlyphEditorStyleConfiguration(content: content))
    }
}

/// The default (identity) style for `GlyphEditor`, which applies no extra styling.
@MainActor public struct DefaultGlyphEditorStyle: GlyphEditorStyle {
    public init() {}
    @MainActor public func makeBody(configuration: GlyphEditorStyleConfiguration) -> some View {
        configuration.content
    }
}

fileprivate extension UIFont {
    convenience init(_ font: Font) {
        switch font {
        case .largeTitle: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle), size: 0)
        case .title: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1), size: 0)
        case .title2: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2), size: 0)
        case .title3: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title3), size: 0)
        case .headline: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline), size: 0)
        case .subheadline: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline), size: 0)
        case .body: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body), size: 0)
        case .callout: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .callout), size: 0)
        case .footnote: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote), size: 0)
        case .caption: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1), size: 0)
        case .caption2: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption2), size: 0)
        default: self.init(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body), size: 0)
        }
    }
}
