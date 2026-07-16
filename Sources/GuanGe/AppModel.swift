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
        settings = AppSettings()
        applyLaunchAtLogin(false)
        notify("已恢复初始设置")
    }

    func toggleGuides() {
        settings.guidesVisible.toggle()
        notify(settings.guidesVisible ? "参考线已显示" : "参考线已隐藏")
    }

    func cycleFrame(_ offset: Int) {
        settings.frame = Self.cycled(FramePreset.allCases, current: settings.frame, offset: offset)
        notify("画幅：\(settings.frame.rawValue)")
    }

    func cycleGuide(_ offset: Int) {
        settings.guide = Self.cycled(GuidePreset.allCases, current: settings.guide, offset: offset)
        notify("构图线：\(settings.guide.rawValue)")
    }

    func cycleLineColor(_ offset: Int) {
        let palette = LinePaletteItem.all
        let current = palette.firstIndex { $0.hex.caseInsensitiveCompare(settings.lineColor) == .orderedSame } ?? 0
        let index = (current + offset + palette.count) % palette.count
        settings.lineColor = palette[index].hex
        notify("线条颜色：\(palette[index].name)")
    }

    func chooseScreenshotDirectory() {
        let panel = NSOpenPanel()
        panel.title = "选择截图保存目录"
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
            showAlert(title: "无法设置开机启动", message: "请将观格放入“应用程序”文件夹后再试。\n\n\(error.localizedDescription)")
        }
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
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    private static func cycled<T: Equatable>(_ values: [T], current: T, offset: Int) -> T {
        guard !values.isEmpty else { return current }
        let index = values.firstIndex(of: current) ?? 0
        return values[(index + offset + values.count) % values.count]
    }
}
