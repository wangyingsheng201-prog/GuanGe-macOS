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

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: Date())
        let indices = displayIndices(for: settings)
        var urls: [URL] = []
        var processes: [Process] = []

        do {
            for (position, displayIndex) in indices.enumerated() {
                let suffix = indices.count > 1 ? "-显示器\(position + 1)" : ""
                let url = directory.appendingPathComponent("观格截图-\(stamp)\(suffix).png")
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

        DispatchQueue.global(qos: .userInitiated).async {
            processes.forEach { $0.waitUntilExit() }
            let failed = processes.first { $0.terminationStatus != 0 }
            DispatchQueue.main.async {
                if let failed {
                    let error = NSError(
                        domain: "GuanGe.Screenshot",
                        code: Int(failed.terminationStatus),
                        userInfo: [NSLocalizedDescriptionKey: "截屏失败。请在“系统设置 → 隐私与安全性 → 屏幕录制”中允许观格录制屏幕。"]
                    )
                    completion(.failure(error))
                } else {
                    completion(.success(urls))
                }
            }
        }
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
