import AppKit

/// macOS offers no API to force the camera off for other apps — but quitting
/// the app that holds it genuinely stops the feed. Best-effort attribution:
/// known camera apps that are currently running, frontmost first.
enum CameraAttribution {
    private static let knownCameraApps: Set<String> = [
        "us.zoom.xos",
        "com.microsoft.teams2",
        "com.microsoft.teams",
        "com.apple.FaceTime",
        "com.apple.PhotoBooth",
        "com.cisco.webexmeetingsapp",
        "com.obsproject.obs-studio",
        "com.loom.desktop",
        "com.skype.skype",
        "com.google.Chrome",
        "com.apple.Safari",
        "org.mozilla.firefox",
        "com.microsoft.edgemac",
        "company.thebrowser.Browser",
    ]

    private static let meetingHosts = ["meet.google.com", "zoom.us", "teams.microsoft",
                                       "webex.com", "whereby.com", "discord.com"]

    private static let scriptableBrowsers: [(bundle: String, name: String, chromeLike: Bool)] = [
        ("com.google.Chrome", "Google Chrome", true),
        ("com.microsoft.edgemac", "Microsoft Edge", true),
        ("com.brave.Browser", "Brave Browser", true),
        ("company.thebrowser.Browser", "Arc", true),
        ("com.apple.Safari", "Safari", false),
    ]

    /// The strongest camera stop macOS allows: close the meeting TAB in scriptable
    /// browsers (surgical), else quit the camera app (force if it refuses).
    /// First browser scripting triggers a one-time Automation permission prompt.
    @discardableResult
    static func stopCamera() -> String {
        for browser in scriptableBrowsers {
            guard NSWorkspace.shared.runningApplications
                .contains(where: { $0.bundleIdentifier == browser.bundle }) else { continue }
            let closed = closeMeetingTabs(appName: browser.name, chromeLike: browser.chromeLike)
            if closed > 0 {
                return "Closed \(closed) meeting tab\(closed == 1 ? "" : "s") in \(browser.name)"
            }
        }
        if let culprit = likelySuspects().first(where: { !isBrowser($0) }) ?? likelySuspects().first {
            let name = culprit.localizedName ?? "the app"
            if !culprit.terminate() { culprit.forceTerminate() }
            return "Quit \(name) to stop the camera"
        }
        return "Camera live — no known app found to stop"
    }

    private static func isBrowser(_ app: NSRunningApplication) -> Bool {
        guard let id = app.bundleIdentifier else { return false }
        return scriptableBrowsers.contains { $0.bundle == id }
    }

    private static func closeMeetingTabs(appName: String, chromeLike: Bool) -> Int {
        let hosts = meetingHosts.map { "theURL contains \"\($0)\"" }.joined(separator: " or ")
        let source = """
        tell application "\(appName)"
          set closedCount to 0
          repeat with w in windows
            set tcount to count of tabs of w
            repeat with i from tcount to 1 by -1
              try
                set theURL to URL of tab i of w
                if \(hosts) then
                  close tab i of w
                  set closedCount to closedCount + 1
                end if
              end try
            end repeat
          end repeat
          return closedCount
        end tell
        """
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        return Int(result?.int32Value ?? 0)
    }

    static func likelySuspects() -> [NSRunningApplication] {
        let running = NSWorkspace.shared.runningApplications.filter {
            guard let id = $0.bundleIdentifier else { return false }
            return knownCameraApps.contains(id)
        }
        // frontmost first — the app you just joined a meeting in
        return running.sorted {
            ($0 == NSWorkspace.shared.frontmostApplication ? 0 : 1)
                < ($1 == NSWorkspace.shared.frontmostApplication ? 0 : 1)
        }
    }
}
