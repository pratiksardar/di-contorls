import Foundation

/// `NotchControls install-hooks` — one command wires Claude Code and Codex
/// so agent events reach the island. Idempotent; never clobbers existing config.
enum InstallHooks {
    static func run() -> Never {
        let bin = ProcessUtils.path(of: getpid()) ?? CommandLine.arguments[0]
        print(installClaude(bin: bin))
        print(installCodex(bin: bin))
        exit(0)
    }

    private static func installClaude(bin: String) -> String {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
        var root: [String: Any] = [:]
        if let data = try? Data(contentsOf: url) {
            guard let parsed = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                return "claude: ~/.claude/settings.json is not valid JSON — left untouched, fix it first"
            }
            root = parsed
        }
        let command = "\(bin) notify --agent \"Claude Code\" 2>/dev/null || true"
        var hooks = root["hooks"] as? [String: Any] ?? [:]
        var added: [String] = []
        for event in ["Notification", "Stop"] {
            var entries = hooks[event] as? [[String: Any]] ?? []
            let present = entries.contains { entry in
                ((entry["hooks"] as? [[String: Any]]) ?? []).contains {
                    ($0["command"] as? String)?.contains("NotchControls") == true
                }
            }
            guard !present else { continue }
            entries.append(["hooks": [["type": "command", "command": command, "timeout": 5]]])
            hooks[event] = entries
            added.append(event)
        }
        guard !added.isEmpty else { return "claude: hooks already installed" }
        root["hooks"] = hooks
        do {
            let data = try JSONSerialization.data(
                withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
            return "claude: installed \(added.joined(separator: " + ")) hooks in ~/.claude/settings.json"
        } catch {
            return "claude: failed to write settings.json — \(error.localizedDescription)"
        }
    }

    private static func installCodex(bin: String) -> String {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/config.toml")
        guard var text = try? String(contentsOf: url, encoding: .utf8) else {
            return "codex: ~/.codex/config.toml not found — skipped (re-run after installing Codex CLI)"
        }
        if text.contains("NotchControls") || text.contains("notify-chain") {
            return "codex: notify already wired"
        }
        if text.range(of: #"^notify\s*="#, options: .regularExpression) != nil {
            return """
            codex: a notify program is already configured — chain it manually: point notify at a \
            script that calls both your current program and: \(bin) notify "$@"
            """
        }
        text = "notify = [\"\(bin)\", \"notify\"]\n\n" + text
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return "codex: notify wired in ~/.codex/config.toml"
        } catch {
            return "codex: failed to write config.toml — \(error.localizedDescription)"
        }
    }
}
