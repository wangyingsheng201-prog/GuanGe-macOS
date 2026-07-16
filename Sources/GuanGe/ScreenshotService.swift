import AppKit

@MainActor
final class ScreenshotService {
    func capture(settings: AppSettings, completion: @escaping (Result<[URL], Error>) -> Void) {
        let directory = URL(fileURLWithPath: settings.screenshotDirectory, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            completion(.failure(error))
            return
        }

        let now = Date()
        let indices = displayIndices(for: settings)
        var urls: [URL] = []
        var processes: [Process] = []

        do {
            for (position, displayIndex) in indices.enumerated() {
                let filename = screenshotFilename(
                    settings: settings,
                    date: now,
                    displayPosition: position,
                    displayCount: indices.count
                )
                let url = availableURL(in: directory, filename: filename)
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                process.arguments = ["-x", "-t", "png", "-D", String(displayIndex), url.path]
                try process.run()
                processes.append(process)
                urls.append(url)
            }
        } catch {
            completion(.failure(error))
            return
        }

        let runningProcesses = processes
        DispatchQueue.global(qos: .userInitiated).async {
            runningProcesses.forEach { $0.waitUntilExit() }
            let failed = runningProcesses.first { $0.terminationStatus != 0 }
            DispatchQueue.main.async {
                if let failed {
                    let error = NSError(
                        domain: "GuanGe.Screenshot",
                        code: Int(failed.terminationStatus),
                        userInfo: [NSLocalizedDescriptionKey: settings.language.text(
                            "截屏失败。请在“系统设置 → 隐私与安全性 → 屏幕录制”中允许观格录制屏幕。",
                            "Screenshot failed. Allow GuanGe under System Settings → Privacy & Security → Screen Recording."
                        )]
                    )
                    completion(.failure(error))
                } else {
                    completion(.success(urls))
                }
            }
        }
    }

    private func screenshotFilename(
        settings: AppSettings,
        date: Date,
        displayPosition: Int,
        displayCount: Int
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateText = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "HHmmss"
        let timeText = dateFormatter.string(from: date)

        let displayNumber = displayPosition + 1
        let displayText = settings.language.text("显示器\(displayNumber)", "Display\(displayNumber)")
        var template = settings.screenshotFilenameTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
        if template.isEmpty { template = AppSettings.defaultScreenshotFilenameTemplate }
        if template.lowercased().hasSuffix(".png") { template.removeLast(4) }

        let usesDisplayToken = template.contains("{display}") || template.contains("{index}")
        let replacements = [
            "{date}": dateText,
            "{time}": timeText,
            "{frame}": settings.frame.displayName(language: settings.language),
            "{guide}": settings.guide.displayName(language: settings.language),
            "{display}": displayText,
            "{index}": String(displayNumber)
        ]
        for (token, value) in replacements { template = template.replacingOccurrences(of: token, with: value) }
        if displayCount > 1, !usesDisplayToken { template += "-\(displayText)" }

        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|\r\n\t")
        var sanitized = template.components(separatedBy: invalid).joined(separator: "-")
        while sanitized.contains("--") { sanitized = sanitized.replacingOccurrences(of: "--", with: "-") }
        sanitized = sanitized.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".-")))
        if sanitized.isEmpty { sanitized = "GuanGe-\(dateText)-\(timeText)" }
        return String(sanitized.prefix(120)) + ".png"
    }

    private func availableURL(in directory: URL, filename: String) -> URL {
        let base = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        var candidate = directory.appendingPathComponent(filename)
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(base)-\(counter).\(ext)")
            counter += 1
        }
        return candidate
    }

    private func displayIndices(for settings: AppSettings) -> [Int] {
        switch settings.screenMode {
        case .all:
            return Array(1...max(1, NSScreen.screens.count))
        case .primary:
            return [1]
        case .selected:
            if let index = NSScreen.screens.firstIndex(where: {
                OverlayController.identifier(for: $0) == settings.selectedDisplayID
            }) {
                return [index + 1]
            }
            return [1]
        }
    }
}
