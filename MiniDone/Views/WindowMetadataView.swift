import AppKit
import SwiftUI

struct WindowMetadataView: NSViewRepresentable {
    let identifier: String
    let title: String

    func makeNSView(context: Context) -> MetadataNSView {
        MetadataNSView(identifier: identifier, title: title)
    }

    func updateNSView(_ nsView: MetadataNSView, context: Context) {
        nsView.identifierValue = identifier
        nsView.titleValue = title
        nsView.applyMetadata()
    }
}

final class MetadataNSView: NSView {
    var identifierValue: String
    var titleValue: String

    init(identifier: String, title: String) {
        self.identifierValue = identifier
        self.titleValue = title
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyMetadata()
    }

    func applyMetadata() {
        guard let window else { return }
        window.identifier = NSUserInterfaceItemIdentifier(identifierValue)
        window.title = titleValue
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(name: nil) { appearance in
            let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua])
            return bestMatch == .darkAqua
                ? NSColor(calibratedWhite: 0.105, alpha: 1)
                : NSColor(calibratedWhite: 0.965, alpha: 1)
        }
    }
}
