<div align="center">
  <img width="300" height="300" src="/assets/icon.png" alt="GlyphMeThat Logo">
  <h1><b>GlyphMeThat</b></h1>
  <p>
    GlyphMeThat is a SwiftUI package for easily displaying and editing attributed strings containing Genmoji (<code>NSAdaptiveImageGlyph</code>) introduced in iOS 18. It provides utilities for decomposition/recomposition and dedicated SwiftUI views.
    <br>
    <i>Compatible with iOS 18.0 and later</i>
  </p>
</div>

<div align="center">
  <a href="https://swift.org">
    <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift Version">
  </a>
  <a href="https://developer.apple.com/ios/">
    <img src="https://img.shields.io/badge/iOS-18.0%2B-blue.svg" alt="iOS">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
  </a>
</div>

---

## Overview

iOS 18 introduced `NSAdaptiveImageGlyph`, allowing dynamic, inline images (like Genmoji) within attributed strings. `GlyphMeThat` simplifies working with these glyphs in SwiftUI applications.

It offers:

1.  **`Glyph` Utility:** A class to decompose `NSAttributedString` containing Genmoji into plain text, image locations, and image data, and recompose them back. Useful for serialization or custom handling.
2.  **`GenmojiText` View:** A SwiftUI view to *display* attributed strings with Genmoji, rendering them correctly inline with text.
3.  **`GlyphEditor` View:** A SwiftUI `UIViewRepresentable` wrapper around `UITextView` that enables *editing* attributed strings with full Genmoji support (insertion, deletion via the standard text editing interactions).

## Features

*   **Display Genmoji:** Render `NSAttributedString` with adaptive image glyphs using the native `GenmojiText` view.
*   **Edit Genmoji:** Use `GlyphEditor` for rich text input that supports Genmoji insertion and editing.
*   **Decomposition/Recomposition:** Programmatically extract Genmoji data from attributed strings and reconstruct them using the `Glyph` utility class.
*   **Customizable Editor:** Configure `GlyphEditor` with placeholders, character limits, text alignment, font, focus, and more using standard SwiftUI modifiers and environment values.
*   **Styling Protocol:** Extend `GlyphEditor`'s appearance using the `GlyphEditorStyle` protocol.
*   **iOS 18+:** Built specifically to leverage the new `NSAdaptiveImageGlyph` capabilities.

## Installation

You can add `GlyphMeThat` to your project using Swift Package Manager.

1.  In Xcode, select **File** > **Add Packages...**
2.  Enter the repository URL: `https://github.com/aeastr/GlyphMeThat.git`
3.  Choose the `main` branch or the latest version tag.
4.  Add the `GlyphMeThat` library to your app target.

Alternatively, add it to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/aeastr/GlyphMeThat.git", from: "1.0.0") 
]
```

And add `GlyphMeThat` to your target's dependencies:

```swift
.target(
    name: "YourAppTarget",
    dependencies: ["GlyphMeThat"]
),
```

## Usage

### Displaying Attributed Strings with Genmoji

Use the `GenmojiText` view to display an `NSAttributedString`.

```swift
import SwiftUI
import GlyphMeThat

struct ContentView: View {
    // Assume `myAttributedString` contains text and NSAdaptiveImageGlyph
    let myAttributedString: NSAttributedString = makeDemoString()

    var body: some View {
        GenmojiText(myAttributedString, imageHeight: 30) // Adjust height as needed
            .font(.title)
            .padding()
    }
}
```

*(Note: Creating `NSAdaptiveImageGlyph` usually happens via system interactions like pasting Genmoji into a `UITextView`. The `recompose` method is useful if you've previously decomposed and stored the data.)*

### Editing Attributed Strings with Genmoji

Use the `GlyphEditor` view, binding it to an `@State` variable holding your `NSAttributedString`.

```swift
import SwiftUI
import GlyphMeThat

struct EditorView: View {
    @State private var attributedText = NSMutableAttributedString(string: "Start typing or paste Genmoji here ✨")
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text("Genmoji Editor:")
                .font(.headline)

            GlyphEditor(attributedText: $attributedText)
                .placeholder("Enter text and Genmoji...")
                .font(.systemFont(ofSize: 18)) // Use UIFont
                .characterLimit(280)
                .frame(height: 200)
                .border(Color.gray.opacity(0.5))
                .focused($isEditorFocused)

            Button("Dismiss Keyboard") {
                isEditorFocused = false
            }
            .padding(.top)

            Divider()

            Text("Live Preview:")
                .font(.headline)
            // Display the edited content using GenmojiText
            GenmojiText(attributedText)
                .padding(.top, 5)

            Spacer()
        }
        .padding()
        .onAppear {
            // Example: Set initial font attribute if needed
            attributedText.addAttribute(
                .font,
                value: UIFont.systemFont(ofSize: 18),
                range: NSRange(location: 0, length: attributedText.length)
            )
        }
    }
}
```

### Customizing the Editor

You can customize `GlyphEditor` using modifiers:

```swift
GlyphEditor(attributedText: $text)
    .glyphEditorStyle(MyCustomStyle())                // Apply a custom style
    .glyphEditorPlaceholder("Type something cool...") // Environment modifier
    .glyphEditorCharacterLimit(100)                  // Environment modifier
    .glyphEditorTextAlignment(.center)               // Environment modifier
    .font(.body))                                    // Direct modifier (UIFont)
    .frame(minHeight: 100)
```

## API Reference

*   **`Glyph`**: Utility class.
    *   `decomposeNSAttributedString(_:)`: Extracts text, image ranges, and image data.
    *   `recomposeAttributedString(...)`: Rebuilds `NSAttributedString` from decomposed parts.
*   **`GenmojiText`**: SwiftUI `View` for displaying attributed strings with Genmoji.
*   **`GlyphEditor`**: SwiftUI `UIViewRepresentable` for editing attributed strings with Genmoji.
    *   Modifiers: `.placeholder()`, `.characterLimit()`, `.font()`, etc.
    *   Environment Modifiers: `.glyphEditorPlaceholder()`, `.glyphEditorCharacterLimit()`, etc.
*   **`GlyphEditorStyle`**: Protocol for creating custom editor styles.
*   **`DefaultGlyphEditorStyle`**: The default identity style.

## License

`GlyphMeThat` is available under the MIT license. See the LICENSE file for more info.
