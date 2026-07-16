import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let model = AppModel()

    private let overlayController = OverlayController()
    private let screenshotService = ScreenshotService()
    private let hotKeyManager = GlobalHotKeyManager()
    private let shutterSound = NSSound(named: NSSound.Name("Tink")) ?? NSSound(named: NSSound.Name("Glass"))
    private var settingsWindow: NSWindow?
    private var supportWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var settingsSubscription: AnyCancellable?
    private var screenSubscription: AnyCancellable?
    private var lastHotkeys: AppHotkeys?
    private var lastRegisteredLanguage: AppLanguage?
    private var lastFrame: FramePreset?
    private var lastGuide: GuidePreset?
    private weak var openPanelMenuItem: NSMenuItem?
    private weak var toggleGuidesMenuItem: NSMenuItem?
    private weak var screenshotMenuItem: NSMenuItem?
    private weak var supportMenuItem: NSMenuItem?
    private weak var quitMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureHotkeys()
        observeSettings()
        observeScreens()
        showSettings()
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.save()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    private func observeSettings() {
        settingsSubscription = model.$settings
            .receive(on: RunLoop.main)
            .sink { [weak self] settings in
                guard let self else { return }
                self.overlayController.update(settings: settings)
                if self.lastHotkeys != settings.hotkeys || self.lastRegisteredLanguage != settings.language {
                    self.lastHotkeys = settings.hotkeys
                    self.lastRegisteredLanguage = settings.language
                    self.hotKeyManager.register(settings.hotkeys, language: settings.language)
                }
                if let previous = self.lastFrame, previous != settings.frame {
                    self.overlayController.showSelectionMessage(
                        settings.frame.displayName(language: settings.language),
                        settings: settings
                    )
                }
                if let previous = self.lastGuide, previous != settings.guide {
                    self.overlayController.showSelectionMessage(
                        settings.guide.displayName(language: settings.language),
                        settings: settings
                    )
                }
                self.lastFrame = settings.frame
                self.lastGuide = settings.guide
                self.updateLocalizedInterface(settings: settings)
                if self.settingsWindow?.isVisible == true { self.settingsWindow?.orderFrontRegardless() }
            }
    }

    private func observeScreens() {
        screenSubscription = NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.overlayController.update(settings: self.model.settings)
            }
    }

    private func configureHotkeys() {
        hotKeyManager.onAction = { [weak self] action in
            guard let self else { return }
            switch action {
            case .toggleGuides: self.model.toggleGuides()
            case .screenshot: self.captureScreenshot()
            case .togglePanel: self.toggleSettings()
            case .previousFrame: self.model.cycleFrame(-1)
            case .nextFrame: self.model.cycleFrame(1)
            case .previousGuide: self.model.cycleGuide(-1)
            case .nextGuide: self.model.cycleGuide(1)
            case .previousColor: self.model.cycleLineColor(-1)
            case .nextColor: self.model.cycleLineColor(1)
            }
        }
        hotKeyManager.onRegistrationError = { [weak self] message in
            self?.model.notify(message)
        }
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "viewfinder", accessibilityDescription: "观格")
            button.toolTip = "观格 · 画面构图参考助手"
        }

        let menu = NSMenu()
        openPanelMenuItem = menu.addItem(withTitle: "打开控制面板", action: #selector(showSettingsFromMenu), keyEquivalent: "")
        toggleGuidesMenuItem = menu.addItem(withTitle: "隐藏参考线", action: #selector(toggleGuidesFromMenu), keyEquivalent: "")
        screenshotMenuItem = menu.addItem(withTitle: "立即截屏", action: #selector(captureFromMenu), keyEquivalent: "")
        menu.addItem(.separator())
        supportMenuItem = menu.addItem(withTitle: "联系和打赏作者", action: #selector(showSupportFromMenu), keyEquivalent: "")
        menu.addItem(.separator())
        quitMenuItem = menu.addItem(withTitle: "退出观格", action: #selector(quitFromMenu), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
        updateLocalizedInterface(settings: model.settings)
    }

    @objc private func showSettingsFromMenu() { showSettings() }
    @objc private func toggleGuidesFromMenu() { model.toggleGuides() }
    @objc private func captureFromMenu() { captureScreenshot() }
    @objc private func showSupportFromMenu() { showSupport() }
    @objc private func quitFromMenu() { NSApp.terminate(nil) }

    private func makeSettingsWindow() -> NSWindow {
        let view = SettingsView(
            model: model,
            captureScreenshot: { [weak self] in self?.captureScreenshot() },
            showSupport: { [weak self] in self?.showSupport() }
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1020, height: 710),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = model.localized("观格 · 控制面板", "GuanGe · Control Panel")
        window.contentView = NSHostingView(rootView: view)
        window.minSize = NSSize(width: 980, height: 680)
        window.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }

    private func showSettings() {
        if settingsWindow == nil { settingsWindow = makeSettingsWindow() }
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func toggleSettings() {
        if settingsWindow?.isVisible == true {
            settingsWindow?.orderOut(nil)
        } else {
            showSettings()
        }
    }

    private func showSupport() {
        if supportWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 860, height: 620),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = model.localized("联系和打赏作者", "Contact & Support the Author")
            window.contentView = NSHostingView(rootView: SupportView(model: model))
            window.minSize = NSSize(width: 760, height: 520)
            window.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 2)
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            supportWindow = window
        }
        supportWindow?.makeKeyAndOrderFront(nil)
        supportWindow?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func captureScreenshot() {
        let settingsWasVisible = settingsWindow?.isVisible == true
        let supportWasVisible = supportWindow?.isVisible == true
        settingsWindow?.orderOut(nil)
        supportWindow?.orderOut(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            self.screenshotService.capture(settings: self.model.settings) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    self.shutterSound?.stop()
                    self.shutterSound?.play()
                    self.overlayController.showScreenshotFlash(settings: self.model.settings)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                        self?.restoreWindows(settingsWasVisible: settingsWasVisible, supportWasVisible: supportWasVisible)
                    }
                case .failure(let error):
                    self.model.showAlert(
                        title: self.model.localized("截屏失败", "Screenshot Failed"),
                        message: error.localizedDescription
                    )
                    self.restoreWindows(settingsWasVisible: settingsWasVisible, supportWasVisible: supportWasVisible)
                }
            }
        }
    }

    private func restoreWindows(settingsWasVisible: Bool, supportWasVisible: Bool) {
        if settingsWasVisible { showSettings() }
        if supportWasVisible { showSupport() }
    }

    private func updateLocalizedInterface(settings: AppSettings) {
        let language = settings.language
        openPanelMenuItem?.title = language.text("打开控制面板", "Open Control Panel")
        toggleGuidesMenuItem?.title = settings.guidesVisible
            ? language.text("隐藏参考线", "Hide Guides")
            : language.text("显示参考线", "Show Guides")
        screenshotMenuItem?.title = language.text("立即截屏", "Capture Screenshot")
        supportMenuItem?.title = language.text("联系和打赏作者", "Contact & Support the Author")
        quitMenuItem?.title = language.text("退出观格", "Quit GuanGe")
        statusItem?.button?.toolTip = language.text("观格 · 画面构图参考助手", "GuanGe · Composition Guide Assistant")
        settingsWindow?.title = language.text("观格 · 控制面板", "GuanGe · Control Panel")
        supportWindow?.title = language.text("联系和打赏作者", "Contact & Support the Author")
    }
}
