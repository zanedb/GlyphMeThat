import XCTest
import UIKit
@testable import GlyphMeThat

/// Tests for GlyphMeThat package.
final class GlyphMeThatTests: XCTestCase {
    func testGlyphEditorModifiers() {
        let emptyAttr = NSAttributedString(string: "")
        var view = GlyphEditor(attributedText: .constant(emptyAttr))
        view = view.placeholder("World")
        XCTAssertEqual(view.placeholder, "World")
        view = view.characterLimit(20)
        XCTAssertEqual(view.characterLimit, 20)
        let f2 = UIFont.italicSystemFont(ofSize: 18)
        view = view.font(f2)
        XCTAssertEqual(view.font, f2)
        view = view.textAlignment(.right)
        XCTAssertEqual(view.textAlignment, .right)
        view = view.allowsEditingTextAttributes(true)
        XCTAssertTrue(view.allowsEditingTextAttributes ?? false)
        view = view.supportsAdaptiveImageGlyph(false)
        XCTAssertEqual(view.supportsAdaptiveImageGlyph, false)
    }
}
