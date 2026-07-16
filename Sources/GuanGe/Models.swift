import AppKit
import Carbon
import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case zhHans = "zh-Hans"
    case english = "en"

    var id: String { rawValue }

    func text(_ chinese: String, _ english: String) -> String {
        self == .zhHans ? chinese : english
    }
}

enum ScreenMode: String, Codable, CaseIterable, Identifiable {
    case all = "全部显示器"
    case primary = "主显示器"
    case selected = "指定显示器"

    var id: String { rawValue }

    func displayName(language: AppLanguage) -> String {
        switch self {
        case .all: return language.text("全部显示器", "All displays")
        case .primary: return language.text("主显示器", "Primary display")
        case .selected: return language.text("指定显示器", "Selected display")
        }
    }
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

    func displayName(language: AppLanguage) -> String {
        if self == .fit { return language.text("适配屏幕", "Fit display") }
        return rawValue
    }

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

    func displayName(language: AppLanguage) -> String {
        switch self {
        case .thirds: return language.text("三分法 / 九宫格", "Rule of Thirds")
        case .halves: return language.text("二等分", "Halves")
        case .fourGrid: return language.text("四等分网格", "4 × 4 Grid")
        case .fiveGrid: return language.text("五等分网格", "5 × 5 Grid")
        case .phiGrid: return language.text("黄金分割网格", "Golden Ratio Grid")
        case .centerCross: return language.text("中心十字", "Center Cross")
        case .goldenTriangleLeft: return language.text("黄金三角形（左）", "Golden Triangle (Left)")
        case .goldenTriangleRight: return language.text("黄金三角形（右）", "Golden Triangle (Right)")
        case .goldenSpiralTL: return language.text("黄金螺旋（左上）", "Golden Spiral (Top Left)")
        case .goldenSpiralTR: return language.text("黄金螺旋（右上）", "Golden Spiral (Top Right)")
        case .goldenSpiralBL: return language.text("黄金螺旋（左下）", "Golden Spiral (Bottom Left)")
        case .goldenSpiralBR: return language.text("黄金螺旋（右下）", "Golden Spiral (Bottom Right)")
        case .dynamicSymmetry: return language.text("动态对称", "Dynamic Symmetry")
        }
    }
}

struct LinePaletteItem: Identifiable, Equatable {
    let chineseName: String
    let englishName: String
    let hex: String
    var id: String { hex }

    func displayName(language: AppLanguage) -> String {
        language == .zhHans ? chineseName : englishName
    }

    static let all: [LinePaletteItem] = [
        .init(chineseName: "天蓝", englishName: "Sky Blue", hex: "#00AEEF"),
        .init(chineseName: "白色", englishName: "White", hex: "#FFFFFF"),
        .init(chineseName: "黑色", englishName: "Black", hex: "#000000"),
        .init(chineseName: "红色", englishName: "Red", hex: "#FF3B30"),
        .init(chineseName: "橙色", englishName: "Orange", hex: "#FF9500"),
        .init(chineseName: "黄色", englishName: "Yellow", hex: "#FFD60A"),
        .init(chineseName: "绿色", englishName: "Green", hex: "#34C759"),
        .init(chineseName: "紫色", englishName: "Purple", hex: "#AF52DE")
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
    static let defaultScreenshotFilenameTemplate = "GuanGe-{date}-{time}"

    var language = AppLanguage.zhHans
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
    var screenshotFilenameTemplate = Self.defaultScreenshotFilenameTemplate
    var launchAtLogin = false
    var hotkeys = AppHotkeys()
}

extension AppSettings {
    private enum CodingKeys: String, CodingKey {
        case language, guidesVisible, screenMode, selectedDisplayID, frame, guide
        case lineColor, lineWidth, lineOpacity, showDiagonals, showSafeFrame
        case safePercent, safeColor, screenshotDirectory, screenshotFilenameTemplate
        case launchAtLogin, hotkeys
    }

    init(from decoder: Decoder) throws {
        let defaults = AppSettings()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? defaults.language
        guidesVisible = try container.decodeIfPresent(Bool.self, forKey: .guidesVisible) ?? defaults.guidesVisible
        screenMode = try container.decodeIfPresent(ScreenMode.self, forKey: .screenMode) ?? defaults.screenMode
        selectedDisplayID = try container.decodeIfPresent(String.self, forKey: .selectedDisplayID) ?? defaults.selectedDisplayID
        frame = try container.decodeIfPresent(FramePreset.self, forKey: .frame) ?? defaults.frame
        guide = try container.decodeIfPresent(GuidePreset.self, forKey: .guide) ?? defaults.guide
        lineColor = try container.decodeIfPresent(String.self, forKey: .lineColor) ?? defaults.lineColor
        lineWidth = try container.decodeIfPresent(Double.self, forKey: .lineWidth) ?? defaults.lineWidth
        lineOpacity = try container.decodeIfPresent(Double.self, forKey: .lineOpacity) ?? defaults.lineOpacity
        showDiagonals = try container.decodeIfPresent(Bool.self, forKey: .showDiagonals) ?? defaults.showDiagonals
        showSafeFrame = try container.decodeIfPresent(Bool.self, forKey: .showSafeFrame) ?? defaults.showSafeFrame
        safePercent = try container.decodeIfPresent(Double.self, forKey: .safePercent) ?? defaults.safePercent
        safeColor = try container.decodeIfPresent(String.self, forKey: .safeColor) ?? defaults.safeColor
        screenshotDirectory = try container.decodeIfPresent(String.self, forKey: .screenshotDirectory) ?? defaults.screenshotDirectory
        screenshotFilenameTemplate = try container.decodeIfPresent(String.self, forKey: .screenshotFilenameTemplate) ?? defaults.screenshotFilenameTemplate
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? defaults.launchAtLogin
        hotkeys = try container.decodeIfPresent(AppHotkeys.self, forKey: .hotkeys) ?? defaults.hotkeys
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(language, forKey: .language)
        try container.encode(guidesVisible, forKey: .guidesVisible)
        try container.encode(screenMode, forKey: .screenMode)
        try container.encode(selectedDisplayID, forKey: .selectedDisplayID)
        try container.encode(frame, forKey: .frame)
        try container.encode(guide, forKey: .guide)
        try container.encode(lineColor, forKey: .lineColor)
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encode(lineOpacity, forKey: .lineOpacity)
        try container.encode(showDiagonals, forKey: .showDiagonals)
        try container.encode(showSafeFrame, forKey: .showSafeFrame)
        try container.encode(safePercent, forKey: .safePercent)
        try container.encode(safeColor, forKey: .safeColor)
        try container.encode(screenshotDirectory, forKey: .screenshotDirectory)
        try container.encode(screenshotFilenameTemplate, forKey: .screenshotFilenameTemplate)
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
        try container.encode(hotkeys, forKey: .hotkeys)
    }
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
