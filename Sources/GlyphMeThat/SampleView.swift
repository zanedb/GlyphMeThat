import SwiftUI
import UIKit

public struct SampleView: View {
    @State private var text: String = ""
    @State private var attributedText: NSAttributedString = NSAttributedString(string: "")
    @FocusState private var isGlyphEditorFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var composeAttributedText: NSAttributedString = NSAttributedString(string: "")
    @FocusState private var isComposeEditorFocused: Bool

    public init() {}
    
    public var body: some View {
        TabView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("GlyphMeThat Demo")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Try out the rich text editor below")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)
                
                // Editor container
                VStack(spacing: 16) {
                    // Status indicator
                    HStack {
                        Image(systemName: isGlyphEditorFocused ? "circle.fill" : "circle")
                            .foregroundColor(isGlyphEditorFocused ? .green : .secondary)
                            .font(.caption)
                        
                        Text(isGlyphEditorFocused ? "Editor active" : "Editor inactive")
                            .font(.caption)
                            .foregroundColor(isGlyphEditorFocused ? .primary : .secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    
                    // Editor
                    GlyphEditor(attributedText: $attributedText)
                        .glyphEditorStyle(MyCustomGlyphEditorStyle())
                        .glyphEditorPlaceholder("Enter rich text…")
                        .glyphEditorCharacterLimit(100)
                        .glyphEditorTextAlignment(.natural)
                        .glyphEditorAllowsEditingTextAttributes(false)
                        .glyphEditorSupportsAdaptiveImageGlyph(true)
                        .font(.body)
                        .focused($isGlyphEditorFocused)
                        .frame(height: 200)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Controls
                HStack(spacing: 16) {
                    Button(action: { isGlyphEditorFocused = true }) {
                        Label("Focus Editor", systemImage: "pencil.line")
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    Button(action: { isGlyphEditorFocused = false }) {
                        Label("Clear Focus", systemImage: "keyboard.chevron.compact.down")
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Footer
                Text("Character count: \(attributedText.string.count)/100")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            .tabItem {
                Label("Editor", systemImage: "pencil")
            }
            
            // Genmoji demo tab
            VStack {
                GenmojiText(attributedText)
                    .font(.body)
                    .padding()
                Spacer()
            }
            .tabItem {
                Label("View", systemImage: "eyes.inverse")
            }
        }
    }
}

struct MyCustomGlyphEditorStyle: GlyphEditorStyle {
    func makeBody(configuration: GlyphEditorStyleConfiguration) -> some View {
        Styled(configuration: configuration)
    }
    private struct Styled: View {
        let configuration: GlyphEditorStyleConfiguration
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            configuration.content
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark
                               ? Color(.systemGray5)
                               : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

/// A view controller representable for picking an image from the photo library.
private struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
