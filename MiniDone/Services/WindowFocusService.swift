import AppKit
import SwiftUI

@MainActor
enum WindowFocusService {
    private static var isOpeningMainWindow = false

    static func openMainWindow(_ openWindow: OpenWindowAction) {
        NSApplication.shared.activate(ignoringOtherApps: true)

        if let window = mainWindow {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
            isOpeningMainWindow = false
            return
        }

        guard !isOpeningMainWindow else { return }
        isOpeningMainWindow = true
        openWindow(id: Constants.Windows.mainID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isOpeningMainWindow = false
        }
    }

    static func openSettings() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    static func quit() {
        NSApplication.shared.terminate(nil)
    }

    private static var mainWindow: NSWindow? {
        let identifier = NSUserInterfaceItemIdentifier(Constants.Windows.mainID)

        return NSApplication.shared.windows.first {
            $0.identifier == identifier || $0.title == "MiniDone"
        }
    }
}
