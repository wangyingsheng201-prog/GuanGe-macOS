import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    let captureScreenshot: () -> Void
    let showSupport: () -> Void

    private var language: AppLanguage { model.settings.language }
    private func t(_ chinese: String, _ english: String) -> String {
        language.text(chinese, english)
    }

    var body: some View {
        VStack(spacing: 10) {
            header
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 10) {
                    displayAndFrame
                    lineAppearance
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    compositionTools
                    screenshotAndSystem
                }
                .frame(maxWidth: .infinity)
            }
            footer
        }
        .padding(14)
        .frame(minWidth: 980, idealWidth: 1020, minHeight: 680, idealHeight: 710)
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let image = NSImage(named: "AppIcon") ?? loadResourceImage("guange-icon", ext: "png") {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 44, height: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(t("观格", "GuanGe"))
                    .font(.title2.bold())
                Text(t("画面构图参考助手 · 所有设置即时生效", "Composition Guide Assistant · Changes apply instantly"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                languageSwitcher
            }
            Spacer()
            if !model.transientMessage.isEmpty {
                Label(model.transientMessage, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                    .transition(.opacity)
            }
        }
    }

    private var languageSwitcher: some View {
        HStack(spacing: 5) {
            Button("简体中文") { model.settings.language = .zhHans }
                .buttonStyle(.plain)
                .foregroundStyle(language == .zhHans ? Color.accentColor : Color.secondary)
                .fontWeight(language == .zhHans ? .semibold : .regular)
            Text("|").foregroundStyle(.tertiary)
            Button("English") { model.settings.language = .english }
                .buttonStyle(.plain)
                .foregroundStyle(language == .english ? Color.accentColor : Color.secondary)
                .fontWeight(language == .english ? .semibold : .regular)
        }
        .font(.caption)
    }

    private var displayAndFrame: some View {
        SettingsGroup(title: t("显示与画面", "Display & Frame"), systemImage: "rectangle.on.rectangle") {
            SettingRow(t("显示范围", "Display scope")) {
                Picker("", selection: $model.settings.screenMode) {
                    ForEach(ScreenMode.allCases) { Text($0.displayName(language: language)).tag($0) }
                }
                .labelsHidden()
                .frame(width: 180)
            }

            if model.settings.screenMode == .selected {
                SettingRow(t("指定显示器", "Selected display")) {
                    Picker("", selection: $model.settings.selectedDisplayID) {
                        ForEach(Array(NSScreen.screens.enumerated()), id: \.offset) { index, screen in
                            Text("\(index + 1). \(screen.localizedName)")
                                .tag(OverlayController.identifier(for: screen))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }
            }

            SettingRow(t("画幅比例", "Aspect ratio")) {
                Picker("", selection: $model.settings.frame) {
                    ForEach(FramePreset.allCases) { Text($0.displayName(language: language)).tag($0) }
                }
                .labelsHidden()
                .frame(width: 180)
            }

            Divider()
            ShortcutPair(
                title: t("轮巡画幅", "Cycle aspect ratio"),
                language: language,
                previous: $model.settings.hotkeys.previousFrame,
                next: $model.settings.hotkeys.nextFrame
            )
        }
    }

    private var compositionTools: some View {
        SettingsGroup(title: t("构图辅助", "Composition Guides"), systemImage: "grid") {
            SettingRow(t("主构图线", "Primary guide")) {
                Picker("", selection: $model.settings.guide) {
                    ForEach(GuidePreset.allCases) { Text($0.displayName(language: language)).tag($0) }
                }
                .labelsHidden()
                .frame(width: 225)
            }

            Toggle(t("显示对角线", "Show diagonals"), isOn: $model.settings.showDiagonals)
            Toggle(t("显示安全框", "Show safe frame"), isOn: $model.settings.showSafeFrame)

            HStack {
                Text(t("安全框范围", "Safe frame size"))
                Slider(value: $model.settings.safePercent, in: 1...99, step: 1)
                    .disabled(!model.settings.showSafeFrame)
                Text("\(Int(model.settings.safePercent))%")
                    .monospacedDigit()
                    .frame(width: 38, alignment: .trailing)
            }

            SettingRow(t("安全框颜色", "Safe frame color")) {
                ColorWell(hex: $model.settings.safeColor)
                    .frame(width: 58, height: 24)
                    .disabled(!model.settings.showSafeFrame)
            }

            Divider()
            ShortcutPair(
                title: t("轮巡构图线", "Cycle primary guide"),
                language: language,
                previous: $model.settings.hotkeys.previousGuide,
                next: $model.settings.hotkeys.nextGuide
            )
        }
    }

    private var lineAppearance: some View {
        SettingsGroup(title: t("线条外观", "Line Appearance"), systemImage: "paintpalette") {
            SettingRow(t("预设颜色", "Preset color")) {
                Picker("", selection: $model.settings.lineColor) {
                    ForEach(LinePaletteItem.all) { item in
                        Text(item.displayName(language: language)).tag(item.hex)
                    }
                }
                .labelsHidden()
                .frame(width: 130)
                ColorWell(hex: $model.settings.lineColor)
                    .frame(width: 58, height: 24)
            }

            HStack {
                Text(t("线条宽度", "Line width"))
                Slider(value: $model.settings.lineWidth, in: 1...8, step: 0.5)
                Text(String(format: "%.1f", model.settings.lineWidth))
                    .monospacedDigit()
                    .frame(width: 34, alignment: .trailing)
            }

            HStack {
                Text(t("线条透明度", "Line opacity"))
                Slider(value: $model.settings.lineOpacity, in: 0.1...1, step: 0.05)
                Text("\(Int(model.settings.lineOpacity * 100))%")
                    .monospacedDigit()
                    .frame(width: 38, alignment: .trailing)
            }

            Divider()
            ShortcutPair(
                title: t("轮巡线条颜色", "Cycle line color"),
                language: language,
                previous: $model.settings.hotkeys.previousColor,
                next: $model.settings.hotkeys.nextColor
            )
        }
    }

    private var screenshotAndSystem: some View {
        SettingsGroup(title: t("截屏与系统", "Screenshot & System"), systemImage: "camera.viewfinder") {
            SettingRow(t("显示/隐藏参考线", "Show/hide guides")) {
                HotkeyRecorder(hotkey: $model.settings.hotkeys.toggleGuides, language: language)
                    .frame(width: 112, height: 28)
            }
            SettingRow(t("截屏", "Screenshot")) {
                HotkeyRecorder(hotkey: $model.settings.hotkeys.screenshot, language: language)
                    .frame(width: 112, height: 28)
            }
            SettingRow(t("显示/隐藏面板", "Show/hide panel")) {
                HotkeyRecorder(hotkey: $model.settings.hotkeys.togglePanel, language: language)
                    .frame(width: 112, height: 28)
            }

            HStack(spacing: 6) {
                Text(t("截图目录", "Screenshot folder"))
                TextField(t("截图目录", "Screenshot folder"), text: $model.settings.screenshotDirectory)
                    .textFieldStyle(.roundedBorder)
                Button(t("浏览", "Browse")) { model.chooseScreenshotDirectory() }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(t("文件名规则", "Filename template"))
                    TextField(AppSettings.defaultScreenshotFilenameTemplate, text: $model.settings.screenshotFilenameTemplate)
                        .textFieldStyle(.roundedBorder)
                }
                Text(t(
                    "可用变量：{date} {time} {frame} {guide} {display} {index}",
                    "Tokens: {date} {time} {frame} {guide} {display} {index}"
                ))
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Toggle(t("登录时自动启动观格", "Launch GuanGe at login"), isOn: Binding(
                get: { model.settings.launchAtLogin },
                set: { model.applyLaunchAtLogin($0) }
            ))
        }
    }

    private var footer: some View {
        VStack(spacing: 5) {
            Button(t("联系和打赏作者", "Contact & Support the Author"), action: showSupport)
                .buttonStyle(.link)
                .font(.caption)

            HStack(spacing: 10) {
                Button(model.settings.guidesVisible
                    ? t("隐藏参考线", "Hide Guides")
                    : t("显示参考线", "Show Guides")) {
                    model.toggleGuides()
                }
                Button(t("立即截屏", "Capture Screenshot"), action: captureScreenshot)
                Button(t("打开截图目录", "Open Screenshot Folder")) { model.openScreenshotDirectory() }
                Button(t("复位 / 重置", "Reset")) {
                    let alert = NSAlert()
                    alert.messageText = t("恢复初始设置？", "Restore Default Settings?")
                    alert.informativeText = t(
                        "画幅、构图线、颜色、目录、文件名规则和所有快捷键都将恢复默认值。",
                        "Aspect ratio, guides, colors, folder, filename template, and shortcuts will be reset."
                    )
                    alert.addButton(withTitle: t("恢复", "Restore"))
                    alert.addButton(withTitle: t("取消", "Cancel"))
                    if alert.runModal() == .alertFirstButtonReturn { model.reset() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func loadResourceImage(_ name: String, ext: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
        return NSImage(contentsOf: url)
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 9) { content }
                .padding(.top, 3)
                .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline)
        }
    }
}

private struct SettingRow<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer(minLength: 10)
            content
        }
    }
}

private struct ShortcutPair: View {
    let title: String
    let language: AppLanguage
    @Binding var previous: HotkeySpec
    @Binding var next: HotkeySpec

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
            Spacer()
            Text(language.text("上一个", "Previous"))
                .font(.caption)
                .foregroundStyle(.secondary)
            HotkeyRecorder(hotkey: $previous, language: language)
                .frame(width: 84, height: 28)
            Text(language.text("下一个", "Next"))
                .font(.caption)
                .foregroundStyle(.secondary)
            HotkeyRecorder(hotkey: $next, language: language)
                .frame(width: 84, height: 28)
        }
    }
}

struct ColorWell: NSViewRepresentable {
    @Binding var hex: String

    func makeNSView(context: Context) -> NSColorWell {
        let well = NSColorWell()
        well.color = NSColor(hex: hex)
        well.target = context.coordinator
        well.action = #selector(Coordinator.changed(_:))
        return well
    }

    func updateNSView(_ well: NSColorWell, context: Context) {
        context.coordinator.parent = self
        let newColor = NSColor(hex: hex)
        if well.color.hexRGB != newColor.hexRGB { well.color = newColor }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject {
        var parent: ColorWell
        init(_ parent: ColorWell) { self.parent = parent }

        @objc func changed(_ sender: NSColorWell) {
            parent.hex = sender.color.hexRGB
        }
    }
}
