import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    let captureScreenshot: () -> Void
    let showSupport: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            header
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 12) {
                    displayAndFrame
                    lineAppearance
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 12) {
                    compositionTools
                    screenshotAndSystem
                }
                .frame(maxWidth: .infinity)
            }
            footer
        }
        .padding(16)
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
                Text("观格")
                    .font(.title2.bold())
                Text("画面构图参考助手 · 所有设置即时生效")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("联系和打赏作者", action: showSupport)
                    .buttonStyle(.link)
                    .font(.caption)
            }
            Spacer()
            if !model.transientMessage.isEmpty {
                Label(model.transientMessage, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                    .transition(.opacity)
            }
            Button(model.settings.guidesVisible ? "隐藏参考线" : "显示参考线") {
                model.toggleGuides()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var displayAndFrame: some View {
        SettingsGroup(title: "显示与画面", systemImage: "rectangle.on.rectangle") {
            SettingRow("显示范围") {
                Picker("", selection: $model.settings.screenMode) {
                    ForEach(ScreenMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()
                .frame(width: 180)
            }

            if model.settings.screenMode == .selected {
                SettingRow("指定显示器") {
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

            SettingRow("画幅比例") {
                Picker("", selection: $model.settings.frame) {
                    ForEach(FramePreset.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()
                .frame(width: 180)
            }

            Divider()
            ShortcutPair(
                title: "轮巡画幅",
                previous: $model.settings.hotkeys.previousFrame,
                next: $model.settings.hotkeys.nextFrame
            )
        }
    }

    private var compositionTools: some View {
        SettingsGroup(title: "构图辅助", systemImage: "grid") {
            SettingRow("主构图线") {
                Picker("", selection: $model.settings.guide) {
                    ForEach(GuidePreset.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()
                .frame(width: 225)
            }

            Toggle("显示对角线", isOn: $model.settings.showDiagonals)
            Toggle("显示安全框", isOn: $model.settings.showSafeFrame)

            HStack {
                Text("安全框范围")
                Slider(value: $model.settings.safePercent, in: 1...99, step: 1)
                    .disabled(!model.settings.showSafeFrame)
                Text("\(Int(model.settings.safePercent))%")
                    .monospacedDigit()
                    .frame(width: 38, alignment: .trailing)
            }

            SettingRow("安全框颜色") {
                ColorWell(hex: $model.settings.safeColor)
                    .frame(width: 58, height: 24)
                    .disabled(!model.settings.showSafeFrame)
            }

            Divider()
            ShortcutPair(
                title: "轮巡构图线",
                previous: $model.settings.hotkeys.previousGuide,
                next: $model.settings.hotkeys.nextGuide
            )
        }
    }

    private var lineAppearance: some View {
        SettingsGroup(title: "线条外观", systemImage: "paintpalette") {
            SettingRow("预设颜色") {
                Picker("", selection: $model.settings.lineColor) {
                    ForEach(LinePaletteItem.all) { item in
                        Text(item.name).tag(item.hex)
                    }
                }
                .labelsHidden()
                .frame(width: 130)
                ColorWell(hex: $model.settings.lineColor)
                    .frame(width: 58, height: 24)
            }

            HStack {
                Text("线条宽度")
                Slider(value: $model.settings.lineWidth, in: 1...8, step: 0.5)
                Text(String(format: "%.1f", model.settings.lineWidth))
                    .monospacedDigit()
                    .frame(width: 34, alignment: .trailing)
            }

            HStack {
                Text("线条透明度")
                Slider(value: $model.settings.lineOpacity, in: 0.1...1, step: 0.05)
                Text("\(Int(model.settings.lineOpacity * 100))%")
                    .monospacedDigit()
                    .frame(width: 38, alignment: .trailing)
            }

            Divider()
            ShortcutPair(
                title: "轮巡线条颜色",
                previous: $model.settings.hotkeys.previousColor,
                next: $model.settings.hotkeys.nextColor
            )
        }
    }

    private var screenshotAndSystem: some View {
        SettingsGroup(title: "截屏与系统", systemImage: "camera.viewfinder") {
            SettingRow("显示/隐藏参考线") {
                HotkeyRecorder(hotkey: $model.settings.hotkeys.toggleGuides)
                    .frame(width: 112, height: 28)
            }
            SettingRow("截屏") {
                HotkeyRecorder(hotkey: $model.settings.hotkeys.screenshot)
                    .frame(width: 112, height: 28)
                Button("立即截屏", action: captureScreenshot)
            }
            SettingRow("显示/隐藏面板") {
                HotkeyRecorder(hotkey: $model.settings.hotkeys.togglePanel)
                    .frame(width: 112, height: 28)
            }

            HStack(spacing: 6) {
                TextField("截图目录", text: $model.settings.screenshotDirectory)
                    .textFieldStyle(.roundedBorder)
                Button("浏览") { model.chooseScreenshotDirectory() }
                Button("打开目录") { model.openScreenshotDirectory() }
            }

            Toggle("登录时自动启动观格", isOn: Binding(
                get: { model.settings.launchAtLogin },
                set: { model.applyLaunchAtLogin($0) }
            ))
        }
    }

    private var footer: some View {
        HStack {
            Text("感谢您的赞赏，如有意见和建议请联系作者：xingheyaoshi@163.com")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("复位 / 重置") {
                let alert = NSAlert()
                alert.messageText = "恢复初始设置？"
                alert.informativeText = "画幅、构图线、颜色、目录和所有快捷键都将恢复默认值。"
                alert.addButton(withTitle: "恢复")
                alert.addButton(withTitle: "取消")
                if alert.runModal() == .alertFirstButtonReturn { model.reset() }
            }
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
    @Binding var previous: HotkeySpec
    @Binding var next: HotkeySpec

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
            Spacer()
            Text("上一个")
                .font(.caption)
                .foregroundStyle(.secondary)
            HotkeyRecorder(hotkey: $previous)
                .frame(width: 84, height: 28)
            Text("下一个")
                .font(.caption)
                .foregroundStyle(.secondary)
            HotkeyRecorder(hotkey: $next)
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
