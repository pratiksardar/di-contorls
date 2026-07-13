# Contributing to NotchControls

Thanks for wanting to make the notch more useful. This is a small, dependency-free Swift codebase — most features are a single file.

## Build & run

```bash
make run        # release build → build/NotchControls.app → launch
make dev        # swift run (debug)
swift build     # typecheck fast
```

Requires macOS 14+ and Xcode command-line tools. No Xcode project — it's pure SPM (`Package.swift`).

## Project layout

```
Sources/NotchControls/
├── App.swift                # app delegate, menu bar, hotkey, CLI entry
├── NotchPanel.swift         # island window + expand/collapse controller
├── NotchView.swift          # island UI (SwiftUI)
├── AudioManager.swift       # CoreAudio system-wide mic mute + in-use detection
├── CameraMonitor.swift      # CMIO camera in-use polling
├── SessionMonitor.swift     # claude/codex session discovery (libproc)
├── ProcessUtils.swift       # argv0 / cwd / CPU-time / ancestry helpers
├── AgentEvents.swift        # banner events + `notify` CLI
├── InstallHooks.swift       # `install-hooks` CLI
├── FileShelf.swift          # drop-on-notch file shelf
├── TeleprompterWindow.swift / TeleprompterView.swift
├── AppSettings.swift        # prefs, settings window, themes
└── UIBits.swift             # shared hover/motion helpers
```

## Ground rules (from PRODUCT.md)

1. **One glance, one truth** — collapsed-strip state is color only: orange = needs you / live, red = muted, green = active, dim = idle.
2. **One click to the core action** — mute is never more than one click or one hotkey away.
3. **Interactive means visible** — everything clickable has a hover state and an affordance.
4. **Motion conveys state** (150–250 ms), honors Reduce Motion. No decorative animation.
5. The island stays **black in both themes** — it extends the physical notch.
6. Zero third-party dependencies. Native APIs over clever workarounds; if a capability needs a hack, scope it honestly (see the camera indicator).

## PR conventions

- **Commitizen-style commit messages** (`feat:`, `fix:`, `chore:`, `docs:`…), imperative mood.
- New user-facing behavior gets a Settings toggle when it could plausibly annoy someone.
- New prefs go through `Pref` in `AppSettings.swift` (key + registered default).
- Run `swift build` clean (no warnings) before opening the PR; describe how you verified the change by hand (this is a GUI app — say what you clicked).
- Keep diffs small and single-purpose.

## Good first issues

- Prompter: countdown (3-2-1), mirror mode, `.pptx` presenter-notes import
- Voice-follow prompter scrolling (SFSpeechRecognizer)
- Quota % alerts (absorb the usage-meter use case)
- Exact-tab focus (iTerm2/Terminal AppleScript, `cursor://` deep links)
- Notification history persistence across launches

Grab anything from [ROADMAP.md](ROADMAP.md) — comment on an issue first if it's an L-sized item so we don't collide.
