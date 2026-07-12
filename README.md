# NotchControls

macOS dynamic-island app that lives at the notch. Meeting controls for any app using your mic/camera (Slack, Meet, Zoom, …) plus a cockpit for your coding agents.

## Install

```bash
git clone <repo-url> && cd controls
make run                                  # build, bundle, launch
build/NotchControls.app/Contents/MacOS/NotchControls install-hooks   # wire Claude Code + Codex
```

Requires macOS 14+. Downloaded release zips are ad-hoc signed — right-click → Open on first launch (see `docs/DISTRIBUTION.md`).

## Features

- **System-wide mic mute** — mutes the default input device at the CoreAudio level, so every app goes silent at once. Devices without a hardware mute control fall back to volume-0 (previous volume restored on unmute). Mute state follows the default device when you switch mics.
- **Mic in-use indicator** — orange mic icon when any app has the mic open, red when muted.
- **Camera in-use indicator** — green camera icon when any app is using a camera. (macOS offers no supported way to force-off the camera for other apps — that needs a CMIO extension, see Phase 2.)
- **Teleprompter** — floating always-on-top panel just under the camera. Type/paste a script, press play, adjust scroll speed and font size. Stays above Meet/Zoom, script persists across launches.
- **Agent notifications** — the island pops open like a live activity when a coding agent needs input (orange, persists as a pulsing bell badge until dismissed) or finishes a run (green, auto-dismisses, coalesced per project). Banners show *agent · project*; pop-ups hold automatically during meetings (mic/camera live) and in quiet hours; right-click a banner to mute its project; the clock button shows recent history. `install-hooks` wires Claude Code (`Notification` + `Stop` hooks) and Codex (`notify`) in one command. Any tool can post events:

  ```bash
  build/NotchControls.app/Contents/MacOS/NotchControls notify \
    --agent "My Tool" --kind attention|done --message "…"
  build/NotchControls.app/Contents/MacOS/NotchControls prompter   # toggle teleprompter
  ```

- **Click-to-focus** — clicking an agent banner jumps to the terminal/editor that owns the session (the notify CLI records its GUI ancestor via the process tree) and clears the event.
- **Sessions dashboard** — the expanded island lists every `claude`/`codex` CLI session running on the machine (argv0 match + controlling-TTY filter to exclude app daemons), with project folder and elapsed time; click a row to jump to its window.
- **Settings** — gear icon on the island, menu bar → Settings…, or `NotchControls settings`. Per-module toggles: camera indicator, teleprompter button, sessions list, agent notifications, auto-expand, attention sound, prompter capture-invisibility.
- **Themes** — System / Light / Dark picker in Settings, applied live to the teleprompter and settings windows. The island itself stays black by design: it extends the physical notch.
- **Global hotkey** — ⌥⇧M toggles mute from anywhere.
- Menu bar item (mic icon) with mute/teleprompter/quit; icon shows mute state.

## Usage

```bash
make run     # build release, bundle build/NotchControls.app, launch
make dev     # swift run (debug, no bundle)
```

Hover the notch to expand the island (Mute / Prompter buttons, device + camera status). Works on non-notch Macs too — floats at top-center.

## Phase 2 ideas

- AI note-taker (Meetily-style): ScreenCaptureKit system-audio + mic capture → whisper.cpp → LLM summary.
- Real camera blocking via a CMIO virtual-camera extension.
- Per-app mic activity attribution.
