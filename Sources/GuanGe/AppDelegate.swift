import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let model = AppModel()

    private let overlayController = OverlayController()
    private let screenshotService = ScreenshotService()
    private let hotKeyManager = GlobalHotKeyManager()
    private var settingsWindow: NSWindow?
    private var supportWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var settingsSubscription: AnyCancellable?
    private var screenSubscription: AnyCancellable?
    private var lastHotkeys: AppHotkeys?
    private weak var toggleGuidesMenuItem: NSMenuItem?

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
                if self.lastHotkeys != settings.hotkeys {
                    self.lastHotkeys = settings.hotkeys
                    self.hotKeyManager.register(settings.hotkeys)
                }
                self.toggleGuidesMenuItem?.title = settings.guidesVisible ? "隐藏参考线" : "显示参考线"
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
        menu.addItem(withTitle: "打开控制面板", action: #selector(showSettingsFromMenu), keyEquivalent: "")
        let toggle = menu.addItem(withTitle: "隐藏参考线", action: #selector(toggleGuidesFromMenu), keyEquivalent: "")
        toggleGuidesMenuItem = toggle
        menu.addItem(withTitle: "立即截屏", action: #selector(captureFromMenu), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "联系和打赏作者", action: #selector(showSupportFromMenu), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出观格", action: #selector(quitFromMenu), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
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
        window.title = "观格 · 控制面板"
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
            window.title = "联系和打赏作者"
            window.contentView = NSHostingView(rootView: SupportView())
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
                case .success(let urls):
                    self.model.notify("已保存 \(urls.count) 张截图")
                case .failure(let error):
                    self.model.showAlert(title: "截屏失败", message: error.localizedDescription)
                }
                if settingsWasVisible { self.showSettings() }
                if supportWasVisible { self.showSupport() }
            }
        }
    }
}
