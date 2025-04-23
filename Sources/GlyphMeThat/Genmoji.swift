import SwiftUI
import UIKit

/// A utility class for decomposing and recomposing attributed strings containing Genmoji (adaptive image glyphs).
///
/// `Glyph` provides methods to extract and re-insert `NSAdaptiveImageGlyph` instances from `NSAttributedString` objects. This enables you to convert rich text with embedded Genmoji into a plain-text representation (plus image data), and then reconstruct the original attributed string from those components.
///
/// - Important: `NSAdaptiveImageGlyph` and `.adaptiveImageGlyph` require iOS 18.0 or later.
///
/// ## Topics
///
/// - Decomposition: `decomposeNSAttributedString(_:)`
/// - Recomposing: `recomposeAttributedString(string:imageRanges:imageData:)`, `recomposeAttributedString(string:imageRanges:imageMap:)`
/// - Inline Representation: ``Glyph/InlineComponent``
public class Glyph {

    @MainActor static let shared = Glyph()

    /// Represents a fragment of plain text or an inline image component in a decomposed attributed string.
    public enum InlineComponent {
        /// A plain text fragment.
        case text(String)
        /// An inline image (Genmoji) fragment.
        case image(UIImage)
    }

    /**
     Decomposes an attributed string containing `NSAdaptiveImageGlyph` image glyphs.

     - Parameter attrStr: The attributed string to decompose.
     - Returns: A tuple containing:
        - The plain text string.
        - An array of `(NSRange, String)` pairs, where each range corresponds to the location of an image glyph and the string is its unique identifier.
        - A dictionary mapping each unique identifier to its image data (PNG format).

     Use this to extract Genmoji from rich text for serialization, storage, or custom rendering.
     */
    public func decomposeNSAttributedString(
        _ attrStr: NSAttributedString
    ) -> (String, [(NSRange, String)], [String: Data]) {
        let string = attrStr.string
        var imageRanges: [(NSRange, String)] = []
        var imageData: [String: Data] = [:]

        attrStr.enumerateAttribute(
            .adaptiveImageGlyph,
            in: NSRange(location: 0, length: attrStr.length),
            options: []
        ) { value, range, _ in
            if let glyph = value as? NSAdaptiveImageGlyph {
                let id = glyph.contentIdentifier
                imageRanges.append((range, id))
                if imageData[id] == nil {
                    imageData[id] = glyph.imageContent
                }
            }
        }

        return (string, imageRanges, imageData)
    }

    /// Recompose an attributed string by inserting image glyphs using stored data mappings.
    /**
     Recomposes an attributed string by inserting Genmoji image glyphs using stored data mappings.

     - Parameters:
        - string: The plain text string.
        - imageRanges: An array of `(NSRange, String)` pairs, where each range specifies where to insert an image glyph and the string is its unique identifier.
        - imageData: A dictionary mapping each unique identifier to its image data (PNG format).
     - Returns: An `NSAttributedString` with embedded `NSAdaptiveImageGlyph` glyphs at the specified ranges.

     Use this to reconstruct a rich text representation from decomposed data.
     */
    public func recomposeAttributedString(
        string: String,
        imageRanges: [(NSRange, String)],
        imageData: [String: Data]
    ) -> NSAttributedString {
        print(
            "[Genmoji Debug] Data overload called. string=\(string), ranges=\(imageRanges), dataKeys=\(Array(imageData.keys))"
        )
        let attrStr = NSMutableAttributedString(string: string)
        var glyphMap: [String: NSAdaptiveImageGlyph] = [:]
        // Create glyphs
        for (id, data) in imageData {
            let glyph = NSAdaptiveImageGlyph(imageContent: data)
            glyphMap[id] = glyph
        }
        // Insert glyphs
        for (range, id) in imageRanges {
            if let glyph = glyphMap[id] {
                attrStr.addAttribute(
                    .adaptiveImageGlyph,
                    value: glyph,
                    range: range
                )
            }
        }
        return attrStr
    }

}

/// A SwiftUI view that renders an attributed string with inline images using `decomposeAttributedString(_:)`.
public struct GenmojiText: View {
    private let components: [Glyph.InlineComponent]
    private let imageHeight: CGFloat

    /// Initializes with an attributed string and optional image height.
    public init(_ attrStr: NSAttributedString,
                imageHeight: CGFloat = UIFont.preferredFont(forTextStyle: .largeTitle).lineHeight) {
        if #available(iOS 18.0, *) {
            let (plain, ranges, data) = Glyph.shared.decomposeNSAttributedString(attrStr)
            print("[Genmoji Debug] GenmojiText.init: plain=‘\(plain)’", "ranges=\(ranges)", "data keys=\(Array(data.keys))")
            var comps: [Glyph.InlineComponent] = []
            var currentIndex = 0

            // Sort ranges by location
            let sorted = ranges.sorted { $0.0.location < $1.0.location }
            for (range, id) in sorted {
                // Text before the glyph
                let prefixLen = range.location - currentIndex
                if prefixLen > 0,
                   let textRange = Range(NSRange(location: currentIndex, length: prefixLen), in: plain) {
                    comps.append(.text(String(plain[textRange])))
                }
                // Inline image
                if let d = data[id], let img = UIImage(data: d) {
                    comps.append(.image(img))
                }
                currentIndex = range.location + range.length
            }
            // Remaining text
            if currentIndex < plain.count,
               let restRange = Range(NSRange(location: currentIndex,
                                              length: plain.count - currentIndex), in: plain) {
                comps.append(.text(String(plain[restRange])))
            }
            self.components = comps
        } else {
            // Fallback: treat entire string as text
            self.components = [.text(attrStr.string)]
        }
        self.imageHeight = imageHeight
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(components.enumerated()), id: \.offset) { _, comp in
                switch comp {
                case .text(let s):
                    Text(s)
                case .image(let img):
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: imageHeight)
                }
            }
        }
    }
}
