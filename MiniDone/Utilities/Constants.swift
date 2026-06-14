import CoreGraphics

enum Constants {
    enum Windows {
        static let mainID = "main-window"
    }

    enum WindowSize {
        static let mainDefaultWidth: CGFloat = 940
        static let mainDefaultHeight: CGFloat = 560
        static let mainMinWidth: CGFloat = 720
        static let mainMinHeight: CGFloat = 480
        static let miniWidth: CGFloat = 300
        static let miniHeight: CGFloat = 280
        static let miniMinHeight: CGFloat = 260
        static let miniMaxHeight: CGFloat = 520
    }

    enum StorageKeys {
        static let language = "settings.language"
        static let theme = "settings.theme"
        static let miniWindowHeight = "window.mini.height"
        static let hasCompletedOnboarding = "onboarding.completed"
    }

    enum DragPayload {
        static let task = "com.krivoy.MiniDone.task"
    }
}
