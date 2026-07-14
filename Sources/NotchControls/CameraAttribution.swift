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
