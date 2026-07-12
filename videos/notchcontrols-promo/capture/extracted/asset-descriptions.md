# Asset inventory

No website capture was performed (open-source project, no marketing site).

No raster assets were captured. All product UI shown in the video must be
recreated as HTML/CSS — the real app's design system is known exactly and is
simple to reproduce:

- **The island**: pure-black rounded-bottom rectangle (bottom radius 18px) pinned
  to the top-center of a Mac desktop, blending with the hardware notch. Collapsed:
  a thin strip with a mic glyph on the left (gray idle / orange live / red muted +
  slash) and a camera glyph on the right (green when in use). A pulsing orange
  bell with a count appears when agents need attention.
- **Expanded island**: event cards (rows: orange ⚠ speech-bubble icon, bold agent
  name "Claude Code", project name in orange, message in dim white, × dismiss),
  session rows (status dot green/orange/dim, agent name bold, project name in a
  per-project hue, "needs you" orange capsule, elapsed time like "2h 41m", tiny ↗),
  two big pill buttons (red "Unmute" with mic-slash / dark "Prompter"), status line
  ("MacBook Pro Microphone · Camera off · Muted" + gear).
- **Teleprompter**: dark glass rounded panel, large rounded-font script text,
  orange chevron reading-guide line, controls bar with white circular play button
  and small sliders. Key visual claim: it does NOT appear in what the audience sees.
- **Colors**: #000 island, #FF9F0A orange (attention/live), #32D74B green (working /
  camera), #FF453A red (muted), white text at 55–90% opacity on black.
- **Type**: SF Pro / system-ui; UI labels 11–14px bold for names.
