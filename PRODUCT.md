# NotchControls

## Register

product — design serves the task. The tool should disappear into the workflow; earned familiarity over novelty (reference bar: Raycast, CleanShot, iStat Menus).

## What it is

A macOS dynamic-island app living at the notch: system-wide mic mute, camera in-use indicator, capture-invisible teleprompter, coding-agent notifications with click-to-focus, and a live dashboard of running Claude Code / Codex sessions.

## Target users

- **Developers** running multiple AI-agent sessions who need ambient awareness (who's blocked, who's done) without alt-tabbing.
- **Content creators** recording/streaming who need instant AV control and a prompter their audience can't see.

## Brand personality

Quiet, instant, trustworthy. The island is an extension of the hardware notch — always black, minimal chrome, status expressed through a small fixed color vocabulary. Never playful at the cost of glanceability.

## Design principles

1. **One glance, one truth**: collapsed strip communicates mic/camera/agent state in color only (orange = live/needs you, red = muted, green = active/done, dim = idle).
2. **One click to the core action**: mute must never be more than one click or one hotkey away.
3. **Interactive means visible**: everything clickable has a hover state and a static affordance.
4. **Motion conveys state** (expand, banner arrival), 150–250ms, honors Reduce Motion.
5. **The island stays black in both themes** — it extends the physical notch. Light/dark theming applies to the teleprompter and settings windows.

## Anti-references

Over-decorated menu-bar apps; glassmorphism-everywhere utilities; notification spam. No decorative motion, no display fonts in UI, no custom form controls where native ones work.

## Visual system (no DESIGN.md — native SwiftUI, tokens live here)

- Surfaces: island = pure black, bottom radius 18; rows = white 5–8% on black, radius 8–10; prompter/settings follow system or forced appearance.
- Type: SF Pro (system) only; 11pt row labels (bold names), 13–14pt controls, caption status line.
- Accents: orange (attention/mic live), red (muted), green (camera/session active, done), white-opacity ramp for hierarchy (≥0.45 for readable text, ≤0.25 only for off-state indicators).
