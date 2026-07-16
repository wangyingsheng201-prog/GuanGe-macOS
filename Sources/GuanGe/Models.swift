import AppKit
import Carbon
import Foundation

enum ScreenMode: String, Codable, CaseIterable, Identifiable {
    case all = "全部显示器"
    case primary = "主显示器"
    case selected = "指定显示器"

    var id: String { rawValue }
}

enum FramePreset: String, Codable, CaseIterable, Identifiable {
    case fit = "适配屏幕"
    case square = "1:1"
    case fourThree = "4:3"
    case threeTwo = "3:2"
    case sixteenTen = "16:10"
    case sixteenNine = "16:9"
    case eighteenNine = "18:9"
    case twentyOneNine = "21:9"
    case academy = "1.85:1"
    case scope = "2.35:1"
    case cinemascope = "2.39:1"
    case verticalFourFive = "4:5"
    case verticalThreeFour = "3:4"
    case verticalNineSixteen = "9:16"

    var id: String { rawValue }

    var aspectRatio: CGFloat? {
        switch self {
        case .fit: return nil
        case .square: return 1
        case .fourThree: return 4 / 3
        case .threeTwo: return 3 / 2
        case .sixteenTen: return 16 / 10
        case .sixteenNine: return 16 / 9
        case .eighteenNine: return 2
        case .twentyOneNine: return 21 / 9
        case .academy: return 1.85
        case .scope: return 2.35
        case .cinemascope: return 2.39
        case .verticalFourFive: return 4 / 5
        case .verticalThreeFour: return 3 / 4
        case .verticalNineSixteen: return 9 / 16
        }
    }
}

enum GuidePreset: String, Codable, CaseIterable, Identifiable {
    case thirds = "三分法 / 九宫格"
    case halves = "二等分"
    case fourGrid = "四等分网格"
    case fiveGrid = "五等分网格"
    case phiGrid = "黄金分割网格"
    case centerCross = "中心十字"
    case goldenTriangleLeft = "黄金三角形（左）"
    case goldenTriangleRight = "黄金三角形（右）"
    case goldenSpiralTL = "黄金螺旋（左上）"
    case goldenSpiralTR = "黄金螺旋（右上）"
    case goldenSpiralBL = "黄金螺旋（左下）"
    case goldenSpiralBR = "黄金螺旋（右下）"
    case dynamicSymmetry = "动态对称"

    var id: String { rawValue }
}

struct LinePaletteItem: Identifiable, Equatable {
    let name: String
    let hex: String
    var id: String { hex }

    static let all: [LinePaletteItem] = [
        .init(name: "天蓝", hex: "#00AEEF"),
        .init(name: "白色", hex: "#FFFFFF"),
        .init(name: "黑色", hex: "#000000"),
        .init(name: "红色", hex: "#FF3B30"),
        .init(name: "橙色", hex: "#FF9500"),
        .init(name: "黄色", hex: "#FFD60A"),
        .init(name: "绿色", hex: "#34C759"),
        .init(name: "紫色", hex: "#AF52DE")
    ]
}

struct HotkeySpec: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    var display: String

    static let toggleGuides = HotkeySpec(keyCode: 5, modifiers: UInt32(controlKey | optionKey), display: "⌃⌥G")
    static let screenshot = HotkeySpec(keyCode: 1, modifiers: UInt32(controlKey | optionKey), display: "⌃⌥S")
    static let togglePanel = HotkeySpec(keyCode: 35, modifiers: UInt32(controlKey | optionKey), display: "⌃⌥P")
    static let previousFrame = HotkeySpec(keyCode: 126, modifiers: UInt32(shiftKey), display: "⇧↑")
    static let nextFrame = HotkeySpec(keyCode: 125, modifiers: UInt32(shiftKey), display: "⇧↓")
    static let previousGuide = HotkeySpec(keyCode: 126, modifiers: UInt32(controlKey), display: "⌃↑")
    static let nextGuide = HotkeySpec(keyCode: 125, modifiers: UInt32(controlKey), display: "⌃↓")
    static let previousColor = HotkeySpec(keyCode: 126, modifiers: UInt32(optionKey), display: "⌥↑")
    static let nextColor = HotkeySpec(keyCode: 125, modifiers: UInt32(optionKey), display: "⌥↓")
}

struct AppHotkeys: Codable, Equatable {
    var toggleGuides = HotkeySpec.toggleGuides
    var screenshot = HotkeySpec.screenshot
    var togglePanel = HotkeySpec.togglePanel
    var previousFrame = HotkeySpec.previousFrame
    var nextFrame = HotkeySpec.nextFrame
    var previousGuide = HotkeySpec.previousGuide
    var nextGuide = HotkeySpec.nextGuide
    var previousColor = HotkeySpec.previousColor
    var nextColor = HotkeySpec.nextColor
}

struct AppSettings: Codable, Equatable {
    var guidesVisible = true
    var screenMode = ScreenMode.all
    var selectedDisplayID = ""
    var frame = FramePreset.sixteenNine
    var guide = GuidePreset.thirds
    var lineColor = "#00AEEF"
    var lineWidth = 2.0
    var lineOpacity = 0.92
    var showDiagonals = false
    var showSafeFrame = false
    var safePercent = 90.0
    var safeColor = "#FFD60A"
    var screenshotDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Pictures")
        .appendingPathComponent("观格截图").path
    var launchAtLogin = false
    var hotkeys = AppHotkeys()
}

extension NSColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        if clean.count == 6 {
            self.init(
                calibratedRed: CGFloat((value >> 16) & 0xff) / 255,
                green: CGFloat((value >> 8) & 0xff) / 255,
                blue: CGFloat(value & 0xff) / 255,
                alpha: alpha
            )
        } else {
            self.init(calibratedWhite: 1, alpha: alpha)
        }
    }

    var hexRGB: String {
        guard let rgb = usingColorSpace(.deviceRGB) else { return "#FFFFFF" }
        return String(
            format: "#%02X%02X%02X",
            Int(round(rgb.redComponent * 255)),
            Int(round(rgb.greenComponent * 255)),
            Int(round(rgb.blueComponent * 255))
        )
    }
}

extension NSRect {
    func fitted(to aspectRatio: CGFloat?) -> NSRect {
        guard let aspectRatio, aspectRatio > 0 else { return self }
        let current = width / height
        if current > aspectRatio {
            let newWidth = height * aspectRatio
            return NSRect(x: midX - newWidth / 2, y: minY, width: newWidth, height: height)
        }
        let newHeight = width / aspectRatio
        return NSRect(x: minX, y: midY - newHeight / 2, width: width, height: newHeight)
    }
}
