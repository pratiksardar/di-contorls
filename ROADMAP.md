# NotchControls — Product Roadmap (PO view)

*Updated 2026-07-12. Supersedes the feature-list draft; PRODUCT.md holds design principles.*

## Vision

**The notch is the cockpit for your work sessions.** Every existing notch app treats it as a media toy; every agent monitor is a passive meter in the menu bar; every prompter is a single-purpose window. NotchControls is the one surface at eye-line that *controls* the session you're in: your mic, your camera exposure, your script, and your fleet of coding agents — with attention routed to you, and one click routing you back.

## Competitive landscape (researched 2026-07)

| Cluster | Players | What they do | What they don't |
|---|---|---|---|
| Notch/dynamic-island apps | **boring.notch** (OSS, 5k+ ★), Notchy, NotchNook, seam ($19.90), TopNotch, Alcove | Media controls, battery, calendar, HUD replacement, file shelf | Nothing about *work sessions*: no AV control, no agents, no prompter. boring.notch has known sleep/wake crashes + battery drain — stability is a wedge |
| Agent session monitors | **so-agentbar** (Claude+Codex sessions, tokens, notifications), **c9watch** (process-scan auto-discovery, MIT), claude-status-bar, ClaudeBar, ClaudeUsageBar, Claude God | Menu-bar status + usage/quota meters | Passive dashboards. No click-to-focus routing, no at-eye-line banners, no per-session "needs you" triage, menu bar not notch |
| Notch teleprompters | **Textream** (OSS, capture-hide, voice highlight), **Tele** (OSS, voice-follow), OpenTeleprompter, CueNotch, NotchPrompter | Scripts at the camera, some capture-invisible, some voice-paced | Single-purpose apps; no meeting/AV context around them |

**Read:** each pillar is validated by an existing audience; the *combination* is unclaimed. so-agentbar/c9watch prove devs want session monitoring; the prompter cluster proves creators pay attention to the notch; boring.notch proves 5k+ stars are available for a notch app that's merely pleasant.

## Differentiation thesis

1. **Control, not display.** Menu-bar monitors *show* agent status; we *route attention*: banner at eye-line → click → land in the owning window. Mute is device-level (all apps at once) and one click on the notch. This interaction loop is the product; widgets are commodities.
2. **Cross-vendor by design.** Claude Code + Codex today via a generic `notify` CLI any tool can call (Gemini CLI, aider, CI, deploys). so-agentbar is the only comparable multi-agent player; we go deeper (hooks both directions, per-session identity by cwd).
3. **The meeting layer nobody has.** Mic/camera/prompter/agents in one surface means we own the "I'm in a meeting while agents work" moment — the exact intersection of our two personas. No competitor spans it.
4. **Boringly reliable.** boring.notch's top complaints are crashes and battery. We stay dependency-free, poll cheaply, and treat stability as a headline feature.

**Positioning line:** *"Your notch, on duty: mute anything, prompt yourself, and know the second an agent needs you."*

## North-star & guardrail metrics

- **North star:** weekly "attention loops" completed (banner → click → focused window).
- Activation: % of installs that wire hooks within first session (target >60% — the `install-hooks` command is the activation feature).
- Retention proxy: DAU/WAU of island expansions; prompter sessions/week (creator side).
- Guardrails: crash-free sessions ≥99.5%, idle CPU <0.5%, battery complaints ≈ 0.

## Releases

### v0.2 — "The agent cockpit" (launch release, ~2 weeks)
*Goal: be the obvious answer to "how do I watch my Claude/Codex fleet".*
- Session states: working / **waiting-on-you** / idle (hook events keyed to session), waiting count on the collapsed strip
- `NotchControls install-hooks` — one command wires Claude Code + Codex (activation-critical)
- PermissionRequest hook + minimum-duration filter for Stop noise; per-repo mute
- Notification history panel; exact-tab focus (iTerm2/Terminal AppleScript, `cursor://` deep link)
- Launch at login, app icon, Developer ID signing + notarization, Homebrew cask
- **Launch:** Show HN, r/ClaudeAI, awesome-claude-code PR, demo GIFs (mute mid-Meet; banner→click→Cursor)

### v0.3 — "The creator kit" (+3 weeks)
*Goal: convert the prompter cluster's audience with a better-integrated tool.*
- Prompter: countdown, live remote keys (speed/jump), mirror mode, script library + .md import, read-time/WPM, click-through mode
- Mic level meter; camera self-preview on hover; screen-share guard (amber island while captured)
- One-click "recording mode" (DND + prompter + notification mute)

### v0.4 — "The meeting brain" (+6 weeks)
*Goal: the moat feature — Meetily-class notes, notch-native.*
- Voice-follow prompter scrolling (Tele/Textream parity, table stakes by then)
- Local AI note-taker: ScreenCaptureKit + mic → whisper.cpp → summary (fully local, no bot joins the call)
- Next-meeting countdown + join link (EventKit)
- Per-session token/cost (join the usage-meter clusters' feature at higher context)

### v1.0 — "Platform" (quarter horizon)
- Widget/module SDK or plugin manifest (let the community add tiles — boring.notch has none)
- Multi-display polish, module reordering, hotkey customization, localization
- Optional paid tier decision point (align with seam's $19.90 one-time precedent; core stays OSS)

## Be-the-best gap plan (competitor comparison → build order)

What each neighbor does better than us today, and the counter-move (✅ = closed as of v0.4.0):

| Competitor | Their edge | Our counter | Status |
|---|---|---|---|
| boring.notch (5k★) | File shelf, media controls, HUD replacement, big community | Shelf ✅ (+ iCloud mirroring + AirDrop they DON'T have); media/HUD as community modules post-SDK; win on stability + purpose | shelf ✅, SDK pending |
| NotchNook / seam | Deep customization; seam's focus sessions + polish | Island sizing + button visibility ✅; per-module toggles ✅; focus/pomodoro pending | sizing ✅ |
| so-agentbar | Token/cost + quota tracking, session states, editor deep-links, subagent detail | States ✅, right-click open-in ✅, subagent badges ✅; **quota/cost is the biggest open gap** | quota ❌ (top priority) |
| c9watch | Zero-setup process discovery | Same technique ✅ + hooks as enrichment ✅ | ✅ |
| Textream / Tele | Voice-follow + word-tracking prompter, .pptx import, phone remote | **Voice-follow is the #2 open gap**; capture-invisibility ✅ matches them | voice ❌ |
| OverSight | Mic/camera on/off alerting with per-app attribution | Camera Guard ✅; **per-app attribution** (which app grabbed the camera) pending | guard ✅, attribution ❌ |
| Alcove (paid) | Polish, notarized, Sparkle updates | Developer ID + notarization + Sparkle — the only money-gated item ($99/yr) | ❌ |

**Build order to "best overall":** 1) per-session token/cost + quota alerts (kills the entire usage-meter category), 2) voice-follow prompter (kills the prompter category), 3) per-app camera/mic attribution (kills OverSight), 4) module SDK (lets the community out-build boring.notch's widget set), 5) sign + notarize + cask (distribution parity with paid apps).

## Borrowed inspiration (validated by neighbors, adapted to our thesis)

**From so-agentbar → v0.2/v0.4:**
- Subagent grouping: parent session row shows "×N agents" expandable (we currently hide children entirely — showing the count is better information)
- Right-click a session row → open in VS Code / Cursor / Terminal / Finder (complements click-to-focus)
- Quota % + threshold alerts (v0.4, absorbs the usage-meter cluster)
- Quiet hours — but our twist is **meeting-aware auto-quiet**: mic/camera live ⇒ banners hold automatically
- Per-project emoji/color for scanning long session lists

**From Textream/Tele → v0.3/v0.4:**
- Word-tracking mode (on-device speech recognition highlights the current word) as the ceiling; voice-activated scroll (scrolls while you speak, pauses on silence) as the v0.4 step before it
- Tap-to-jump + scroll-to-catch-up with timer resume (v0.3, cheap)
- .pptx presenter-notes import alongside .md (webinar crowd)
- Phone-as-confidence-monitor via local-network QR; "director mode" (someone else pushes script edits live) — later, team differentiator
- OpenDyslexic font option (cheap, inclusive)

**From c9watch:** zero-setup process discovery as the default posture — we already have it; keep hooks *optional enrichment*, never a requirement to see sessions.

**From boring.notch/seam:** file shelf validated (v1.0 module); seam's focus-sessions validates our pomodoro+DND; their stability complaints validate "boringly reliable" as marketing copy.

**Deliberately NOT borrowing:** media controls + audio visualizers (commodity in every notch app; blurs positioning — community module at best), pixel-art pet animations (toy), HUD replacement (another cluster's core feature), wallpaper notch-hiding.

## Risks

- **Fast-follow risk:** c9watch/so-agentbar add a notch UI, or boring.notch adds an agent widget → ship v0.2 fast; moat is the full loop, not any single widget.
- **Apple risk:** notch-adjacent APIs shift each macOS release → keep the island logic behind one controller; non-notch fallback already works.
- **Hook fragility:** Claude Code hook schema changes → `install-hooks` owns the contract, versioned.
- **Scope risk:** two personas can blur the story → lead every release with ONE persona (v0.2 dev, v0.3 creator, v0.4 both).
