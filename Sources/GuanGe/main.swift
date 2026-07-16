import AppKit

MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    application.run()
}
import AppKit

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
