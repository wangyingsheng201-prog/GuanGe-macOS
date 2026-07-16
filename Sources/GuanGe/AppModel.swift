import AppKit
import Combine
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet { save() }
    }
    @Published var transientMessage = ""

    private static let storageKey = "GuanGe.AppSettings.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let value = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = value
        } else {
            settings = AppSettings()
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    func reset() {
        let language = settings.language
        settings = AppSettings()
        settings.language = language
        applyLaunchAtLogin(false)
        notify(localized("已恢复初始设置", "Default settings restored"))
    }

    func toggleGuides() {
        settings.guidesVisible.toggle()
        notify(settings.guidesVisible
            ? localized("参考线已显示", "Guides shown")
            : localized("参考线已隐藏", "Guides hidden"))
    }

    func cycleFrame(_ offset: Int) {
        settings.frame = Self.cycled(FramePreset.allCases, current: settings.frame, offset: offset)
    }

    func cycleGuide(_ offset: Int) {
        settings.guide = Self.cycled(GuidePreset.allCases, current: settings.guide, offset: offset)
    }

    func cycleLineColor(_ offset: Int) {
        let palette = LinePaletteItem.all
        let current = palette.firstIndex { $0.hex.caseInsensitiveCompare(settings.lineColor) == .orderedSame } ?? 0
        let index = (current + offset + palette.count) % palette.count
        settings.lineColor = palette[index].hex
        notify("\(localized("线条颜色", "Line color"))：\(palette[index].displayName(language: settings.language))")
    }

    func chooseScreenshotDirectory() {
        let panel = NSOpenPanel()
        panel.title = localized("选择截图保存目录", "Choose Screenshot Folder")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            settings.screenshotDirectory = url.path
        }
    }

    func openScreenshotDirectory() {
        let url = URL(fileURLWithPath: settings.screenshotDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }

    func applyLaunchAtLogin(_ enabled: Bool) {
        settings.launchAtLogin = enabled
        guard #available(macOS 13.0, *) else { return }
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            settings.launchAtLogin = false
            showAlert(
                title: localized("无法设置开机启动", "Unable to Enable Launch at Login"),
                message: localized(
                    "请将观格放入“应用程序”文件夹后再试。",
                    "Move GuanGe to the Applications folder and try again."
                ) + "\n\n\(error.localizedDescription)"
            )
        }
    }

    func localized(_ chinese: String, _ english: String) -> String {
        settings.language.text(chinese, english)
    }

    func notify(_ text: String) {
        transientMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.transientMessage == text { self?.transientMessage = "" }
        }
    }

    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: localized("好", "OK"))
        alert.runModal()
    }

    private static func cycled<T: Equatable>(_ values: [T], current: T, offset: Int) -> T {
        guard !values.isEmpty else { return current }
        let index = values.firstIndex(of: current) ?? 0
        return values[(index + offset + values.count) % values.count]
    }
}
