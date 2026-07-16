import AppKit
import Carbon

enum HotKeyAction: UInt32, CaseIterable {
    case toggleGuides = 1
    case screenshot
    case togglePanel
    case previousFrame
    case nextFrame
    case previousGuide
    case nextGuide
    case previousColor
    case nextColor
}

final class GlobalHotKeyManager {
    var onAction: ((HotKeyAction) -> Void)?
    var onRegistrationError: ((String) -> Void)?

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandlerRef: EventHandlerRef?
    private let signature: OSType = 0x47554745 // GUGE

    init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr, hotKeyID.signature == manager.signature,
                      let action = HotKeyAction(rawValue: hotKeyID.id) else {
                    return OSStatus(eventNotHandledErr)
                }
                DispatchQueue.main.async { manager.onAction?(action) }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }

    deinit {
        unregisterAll()
        if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
    }

    func register(_ hotkeys: AppHotkeys, language: AppLanguage) {
        unregisterAll()
        let items: [(HotKeyAction, HotkeySpec)] = [
            (.toggleGuides, hotkeys.toggleGuides),
            (.screenshot, hotkeys.screenshot),
            (.togglePanel, hotkeys.togglePanel),
            (.previousFrame, hotkeys.previousFrame),
            (.nextFrame, hotkeys.nextFrame),
            (.previousGuide, hotkeys.previousGuide),
            (.nextGuide, hotkeys.nextGuide),
            (.previousColor, hotkeys.previousColor),
            (.nextColor, hotkeys.nextColor)
        ]

        var failures: [String] = []
        for (action, spec) in items {
            var reference: EventHotKeyRef?
            let identifier = EventHotKeyID(signature: signature, id: action.rawValue)
            let status = RegisterEventHotKey(
                spec.keyCode,
                spec.modifiers,
                identifier,
                GetApplicationEventTarget(),
                0,
                &reference
            )
            if status == noErr, let reference {
                hotKeyRefs.append(reference)
            } else {
                failures.append(spec.display)
            }
        }
        if !failures.isEmpty {
            onRegistrationError?(language.text(
                "这些快捷键已被系统或其他应用占用：\(failures.joined(separator: "、"))",
                "These shortcuts are already used by macOS or another app: \(failures.joined(separator: ", "))"
            ))
        }
    }

    private func unregisterAll() {
        hotKeyRefs.forEach { UnregisterEventHotKey($0) }
        hotKeyRefs.removeAll()
    }
}

enum HotkeyFormatter {
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }

    static func display(keyCode: UInt16, flags: NSEvent.ModifierFlags, language: AppLanguage) -> String {
        var text = ""
        if flags.contains(.control) { text += "⌃" }
        if flags.contains(.option) { text += "⌥" }
        if flags.contains(.shift) { text += "⇧" }
        if flags.contains(.command) { text += "⌘" }
        text += keyName(for: keyCode, language: language)
        return text
    }

    private static func keyName(for keyCode: UInt16, language: AppLanguage) -> String {
        let special: [UInt16: String] = [
            36: "↩", 48: "⇥", 49: language.text("空格", "Space"), 51: "⌫", 53: "⎋",
            115: "↖", 116: "⇞", 117: "⌦", 119: "↘", 121: "⇟",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        if let value = special[keyCode] { return value }
        let letters: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
            38: "J", 40: "K", 45: "N", 46: "M",
            18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 25: "9",
            26: "7", 28: "8", 29: "0"
        ]
        return letters[keyCode] ?? language.text("键\(keyCode)", "Key \(keyCode)")
    }
}
