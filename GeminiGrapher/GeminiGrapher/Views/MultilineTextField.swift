import SwiftUI

struct MultilineTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var font: NSFont = .systemFont(ofSize: NSFont.systemFontSize)
    var onCommandReturn: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = CommandReturnTextView()

        textView.delegate = context.coordinator
        textView.onCommandReturn = onCommandReturn
        textView.font = font
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.drawsBackground = false
        textView.textColor = .labelColor
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.textContainer?.lineFragmentPadding = 4
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? CommandReturnTextView else { return }

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }

        textView.onCommandReturn = onCommandReturn
        textView.font = font
        textView.needsDisplay = true
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MultilineTextField
        weak var textView: NSTextView?

        init(_ parent: MultilineTextField) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

class CommandReturnTextView: NSTextView {
    var onCommandReturn: (() -> Void)?
    var placeholderString: String?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 && event.modifierFlags.contains(.command) {
            onCommandReturn?()
            return
        }
        super.keyDown(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if string.isEmpty {
            let placeholder = "Describe what you want to adjust..."
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.tertiaryLabelColor,
                .font: font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ]
            let inset = textContainerInset
            let padding = textContainer?.lineFragmentPadding ?? 0
            let rect = NSRect(
                x: inset.width + padding,
                y: inset.height,
                width: bounds.width - (inset.width + padding) * 2,
                height: bounds.height - inset.height * 2
            )
            placeholder.draw(in: rect, withAttributes: attrs)
        }
    }
}
