import Foundation

/// UI tests can exercise the real screens without downloading models or
/// starting MLX. These switches are available only in debug simulator builds.
enum UILayoutAudit {
    static var isEnabled: Bool {
        #if DEBUG && targetEnvironment(simulator)
        ProcessInfo.processInfo.arguments.contains("--ui-layout-audit")
        #else
        false
        #endif
    }

    static var showsWorkspace: Bool {
        isEnabled && !ProcessInfo.processInfo.arguments.contains("--ui-first-run")
    }
}
