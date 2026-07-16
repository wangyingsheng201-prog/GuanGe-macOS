import AppKit

@MainActor
final class OverlayController {
    private var windows: [NSWindow] = []

    func update(settings: AppSettings) {
        windows.forEach { $0.close() }
        windows.removeAll()
        guard settings.guidesVisible else { return }

        for screen in targetScreens(for: settings) {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.acceptsMouseMovedEvents = false
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.contentView = GuideView(settings: settings)
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    func displayIndex(for settings: AppSettings) -> Int? {
        switch settings.screenMode {
        case .all:
            return nil
        case .primary:
            return 1
        case .selected:
            guard let screen = targetScreens(for: settings).first,
                  let index = NSScreen.screens.firstIndex(of: screen) else { return 1 }
            return index + 1
        }
    }

    private func targetScreens(for settings: AppSettings) -> [NSScreen] {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return [] }
        switch settings.screenMode {
        case .all:
            return screens
        case .primary:
            return [screens[0]]
        case .selected:
            if let match = screens.first(where: { Self.identifier(for: $0) == settings.selectedDisplayID }) {
                return [match]
            }
            return [screens[0]]
        }
    }

    static func identifier(for screen: NSScreen) -> String {
        if let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return number.stringValue
        }
        return screen.localizedName
    }
}
