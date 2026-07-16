import AppKit
import SwiftUI

struct HotkeyRecorder: NSViewRepresentable {
    @Binding var hotkey: HotkeySpec

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> RecorderView {
        let view = RecorderView()
        view.display = hotkey.display
        view.onRecorded = { context.coordinator.parent.hotkey = $0 }
        return view
    }

    func updateNSView(_ view: RecorderView, context: Context) {
        context.coordinator.parent = self
        if !view.isRecording { view.display = hotkey.display }
    }

    final class Coordinator {
        var parent: HotkeyRecorder
        init(_ parent: HotkeyRecorder) { self.parent = parent }
    }
}

final class RecorderView: NSView {
    var onRecorded: ((HotkeySpec) -> Void)?
    var display = "" { didSet { label.stringValue = display } }
    private(set) var isRecording = false
    private let label = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        label.alignment = .center
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        addSubview(label)
    }

    required init?(coder: NSCoder) { nil }
    override var acceptsFirstResponder: Bool { true }

    override func layout() {
        super.layout()
        label.frame = bounds.insetBy(dx: 6, dy: 3)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        isRecording = true
        label.stringValue = "请按新快捷键…"
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        layer?.borderWidth = 2
    }

    override func keyDown(with event: NSEvent) {
        record(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording else { return false }
        record(event)
        return true
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 1
        label.stringValue = display
        return super.resignFirstResponder()
    }

    private func record(_ event: NSEvent) {
        guard isRecording, !event.isARepeat else { return }
        if event.keyCode == 53 {
            _ = window?.makeFirstResponder(nil)
            return
        }
        let allowed = event.modifierFlags.intersection([.command, .option, .control, .shift])
        let name = HotkeyFormatter.display(keyCode: event.keyCode, flags: allowed)
        let value = HotkeySpec(
            keyCode: UInt32(event.keyCode),
            modifiers: HotkeyFormatter.carbonModifiers(from: allowed),
            display: name
        )
        display = name
        onRecorded?(value)
        _ = window?.makeFirstResponder(nil)
    }
}
