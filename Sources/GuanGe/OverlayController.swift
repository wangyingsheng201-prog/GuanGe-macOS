import AppKit

@MainActor
final class OverlayController {
    private var windows: [NSWindow] = []
    private var messageWindows: [NSWindow] = []
    private var flashWindows: [NSWindow] = []
    private var messageToken = UUID()
    private var flashToken = UUID()

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

    func showSelectionMessage(_ text: String, settings: AppSettings) {
        messageToken = UUID()
        let token = messageToken
        messageWindows.forEach { $0.close() }
        messageWindows = targetScreens(for: settings).map { screen in
            let window = feedbackWindow(
                for: screen,
                levelOffset: 2,
                contentView: CenterMessageView(text: text)
            )
            window.alphaValue = 0
            window.orderFrontRegardless()
            return window
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.06
            messageWindows.forEach { $0.animator().alphaValue = 1 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, self.messageToken == token else { return }
            let fadingWindows = self.messageWindows
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                fadingWindows.forEach { $0.animator().alphaValue = 0 }
            } completionHandler: { [weak self] in
                guard let self, self.messageToken == token else { return }
                fadingWindows.forEach { $0.close() }
                self.messageWindows.removeAll()
            }
        }
    }

    func showScreenshotFlash(settings: AppSettings) {
        flashToken = UUID()
        let token = flashToken
        flashWindows.forEach { $0.close() }
        flashWindows = targetScreens(for: settings).map { screen in
            let view = NSView(frame: .zero)
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor.white.cgColor
            let window = feedbackWindow(for: screen, levelOffset: 3, contentView: view)
            window.alphaValue = 0
            window.orderFrontRegardless()
            return window
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.035
            flashWindows.forEach { $0.animator().alphaValue = 0.14 }
        } completionHandler: { [weak self] in
            guard let self, self.flashToken == token else { return }
            let fadingWindows = self.flashWindows
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.11
                fadingWindows.forEach { $0.animator().alphaValue = 0 }
            } completionHandler: { [weak self] in
                guard let self, self.flashToken == token else { return }
                fadingWindows.forEach { $0.close() }
                self.flashWindows.removeAll()
            }
        }
    }

    private func feedbackWindow(for screen: NSScreen, levelOffset: Int, contentView: NSView) -> NSWindow {
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
        window.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + levelOffset)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.contentView = contentView
        return window
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

private final class CenterMessageView: NSView {
    private let text: String

    init(text: String) {
        self.text = text
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) { nil }
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.9)
        shadow.shadowBlurRadius = 5
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        let attributed = NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.systemFont(ofSize: 28, weight: .semibold),
                .foregroundColor: NSColor.systemYellow,
                .paragraphStyle: paragraph,
                .shadow: shadow
            ]
        )
        let size = attributed.size()
        let rect = NSRect(
            x: bounds.midX - min(size.width + 24, bounds.width - 40) / 2,
            y: bounds.midY - (size.height + 12) / 2,
            width: min(size.width + 24, bounds.width - 40),
            height: size.height + 12
        )
        attributed.draw(in: rect)
    }
}
