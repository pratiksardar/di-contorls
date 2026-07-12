---
format: 1920x1080
message: "Your notch tells you the second something needs you — and gives you back your mic, your script, and your flow."
arc: PAS — hook → pain → agitation → product intro → proof demos → CTA
audience: developers running AI coding agents + creators who present on camera
mode: autonomous
music: none (offline build — VO only)
---

## Video direction

- palette system (from frame.md): ink-black `#000000` canvas with `#1A1918` alt panels; single fire accent `#FF9F0A` (attention, key words, the island's "needs you" language); paper-white text ramp at 90/60/40% opacity; hairline dividers `1px` white 12%. Product-semantic colors appear ONLY inside recreated app UI: `#32D74B` green (working/camera), `#FF453A` red (muted). Display type: SF Pro Display lowercase weight 900 as graphic primitive; chrome/labels: mono uppercase 0.14em tracking; UI recreations use SF Pro 11–14px per the asset notes.
- motion grammar + reveal model: smooth long-tail settles (`power3` default, `expo.out` on fast arrivals) — no bounce, no overshoot. Every frame reveals each piece on its spoken cue with the back ~50% carrying reveals; nothing front-loads. Entrances via `fromTo` only; all motion on one paused GSAP timeline; no repeat/yoyo, no randomness.
- rhythm / held frames: Frame 3 ends on a long held read ("…is invisible" sits in silence), Frame 9's URL holds still for the final ~1.5s. All other frames keep revealing to the VO. Aliveness during any hold: subtle jitter at most (`sine-wave-loop`, low amplitude).
- negative list: no slideshow (front-load-then-freeze) and no screensaver (independent floaters); no lazy breathing; no back-half pans/pushes; no bouncy eases; no purple-blue AI gradients or bokeh; no real browser chrome, screenshots, or stock UI — every surface is a deliberate flat recreation in the brand system; green/red never used outside recreated UI; bottom 17% caption band stays clear.
- scene-window scaling: per-frame `duration` values are synced to the real voice takes and are authoritative; the Scene `(a–b s)` windows below were written against estimates — treat them as PROPORTIONAL guides and scale each frame's scene boundaries to fit its synced `duration` exactly.

## Frame 1 — 2:47 PM

- scene: Time-stamp and situation land as bare kinetic type on black — the afternoon everyone knows
- voiceover: "2:47 PM. You're on a call. Camera's on."
- duration: 3.349s
- transition_in: cut
- status: animated
- src: compositions/frames/01-hook.html
- type: hook
- persuasion: Pain validation
- beat: tension
- blueprint: kinetic-type-beats (Reproduce)
- sfx: soft-tick, ui-pop
- asset_candidates:

narrativeRole: Drop the viewer into the exact moment the whole video lives in — a specific, familiar afternoon. No product, no promise yet; pure recognition.
keyMessage: You know this exact moment.

Scene 1 (0.0–1.6s): bare ink-black field; "2:47 pm" lands alone dead-center as display lowercase 900 via hard-cut (`discrete-text-sequence`), settling on a long tail — Centered, ~45% of frame, mono timestamp chip above it in accent orange.
Scene 2 (1.6–3.4s): on "you're on a call", the timestamp hard-cuts away and "you're on a call." lands the same way (`discrete-text-sequence`) — the swap IS the beat; a thin hairline rule draws on beneath (`svg-path-draw`).
Scene 3 (3.4–5.0s): on "camera's on", a small recreated camera-dot pill (green dot + mono "CAMERA ON") spring-pops in (`spring-pop-entrance`, smooth settle) just under the line; everything holds still for the cut.

## Frame 2 — Behind the meeting window

- scene: Recognizable app windows (meeting, editor, terminals) pile up and bury an orange "needs your input · waiting 22m" prompt that the viewer can see but "you" cannot
- voiceover: "Behind that window? Three coding agents. And one of them — has been waiting on you for twenty minutes."
- duration: 6.037s
- transition_in: crossfade
- status: animated
- src: compositions/frames/02-buried.html
- type: pain_point
- persuasion: Pain agitation
- beat: anxiety + overwhelm
- blueprint: overwhelm-surround (Adapt)
- sfx: whoosh-soft, notification-muffled
- asset_candidates:

narrativeRole: Make the invisible cost visible: the blocked agent is right there on screen, buried. The audience feels the waste before it's named.
keyMessage: Your agents stall silently while you're busy.

Adapt: keep the surround/close-in signature; the viewer's avatar becomes a recreated meeting window at center, and the surrounding elements are terminal windows that pile OVER an orange prompt instead of icons circling.
Scene 1 (0.0–1.8s): a flat recreated video-call window (dark panel, four blurred participant tiles, green cam dot) seats center via scale-settle (`spring-pop-entrance`, smooth) — Centered, ~55% of frame, 3 depth layers (black field, faint desktop hairlines, window).
Scene 2 (1.8–4.2s): on "three coding agents", three flat terminal windows fly in sequentially from the wings (`center-outward-expansion` reversed — inward) and stack BEHIND the call window, each tagged with a mono label (claude · api / claude · web / codex · infra); layered-depth, overlapping 60/40 left.
Scene 3 (4.2–6.6s): on "waiting on you", the camera pans/zooms to a sliver of screen edge (`coordinate-target-zoom`) where an orange banner "needs your input — waiting 22m" peeks out from UNDER the pile, mostly hidden; it pulses once dimly (`asr-keyword-glow` on the orange chip).
Scene 4 (6.6–8.0s): on "twenty minutes", a mono counter beside the buried banner ticks 19:58 → 22:00 (`counting-dynamic-scale`, restrained size growth); hold the claustrophobic read.

## Frame 3 — Everything invisible

- scene: Solo pain lines land on bare black — "Muted? Unmuted?" swaps in place; then the thesis of the pain: all of it is invisible
- voiceover: "Also — are you muted? Are you sure? Everything you're worried about right now… is invisible."
- duration: 5.909s
- transition_in: crossfade
- status: animated
- src: compositions/frames/03-invisible.html
- type: pain_point
- persuasion: Negative contrast
- beat: anxiety → tension
- blueprint: kinetic-type-beats (Adapt)
- sfx: soft-tick
- asset_candidates:

narrativeRole: Widen from one pain to the pattern — mic state, agent state, script — none of it has a home on screen. Sets up the notch as the answer.
keyMessage: The anxiety is invisibility.

Adapt: keep the in-place token-swap signature; the swap slot is the mic state word, then the shape resolves on a line that fades INTO near-black instead of a payoff pop — invisibility acted out by the type itself.
Scene 1 (0.0–2.2s): "are you muted?" lands center (`discrete-text-sequence`); on "are you sure?", only the token swaps in place — muted? → unmuted? → muted?? (`discrete-text-sequence`, in-place token cycle), each swap on a tick — Centered, ~40%.
Scene 2 (2.2–4.6s): on "everything you're worried about", the mic line clears via hard cut and three small mono ghost-chips reveal one-per-cue (mic state · agent state · your script) in a horizontal rule-of-thirds row, each at 40% opacity (`dynamic-content-sequencing`).
Scene 3 (4.6–7.0s): on "…is invisible", the display line "invisible." lands at 90% then decays to 12% opacity in place (the word literally disappears while you watch); everything else fades with it; long held near-black read — the frame's deliberate stillness beat.

## Frame 4 — The notch, on duty

- scene: A black Mac menu-bar strip with a notch; the island slides out from under it, mic + camera glyphs glowing; the name lands beneath
- voiceover: "Your Mac has one spot your eyes never leave. Meet NotchControls."
- duration: 4.629s
- transition_in: zoom-through
- status: animated
- src: compositions/frames/04-intro.html
- type: product_intro
- persuasion: Friction reduction
- beat: relief + curiosity
- blueprint: kinetic-type-beats (Adapt)
- sfx: whoosh-soft, ui-pop
- asset_candidates:

narrativeRole: The turn. The wasted pixel real estate from Frame 3's world becomes the stage; product named exactly once, resolving on the island itself.
keyMessage: The answers live at eye level now.

Adapt: keep the hard-cut value-beats-resolving-on-the-name signature; the "logo" the beats resolve onto is the recreated island itself sliding out of the notch.
Scene 1 (0.0–2.0s): a full-width recreated menu-bar strip (pure black, centered notch cutout, faint mono menu items) sits at the top edge; on "one spot", a soft accent underline draws beneath the notch (`svg-path-draw`) while the line "one spot your eyes never leave." lands center-frame (`discrete-text-sequence`) — full-width strip + centered text, top ~83% respected.
Scene 2 (2.0–4.2s): on "Meet NotchControls", the text hard-cuts away; the island slides down out of the notch (`card-morph-anchor` feel via uniform scale/translate, smooth long-tail) revealing mic glyph (white) left and camera glyph right; a subtle `ambient-glow-bloom` blooms behind the notch once.
Scene 3 (4.2–6.0s): the wordmark "notchcontrols" assembles beneath in display lowercase 900 via per-word stagger (`dynamic-content-sequencing`), mono sub-line "your notch, on duty" fades to 60%; hold still.

## Frame 5 — Click, you're there

- scene: Recreated island pops open with a banner "Claude Code · api — needs your input"; a cursor clicks it; the right editor window snaps to front
- voiceover: "An agent needs you? Your notch says so — the second it happens. Click the banner… and you're in the right window."
- duration: 6.763s
- transition_in: crossfade
- status: animated
- src: compositions/frames/05-banner.html
- type: feature_showcase
- persuasion: Show-don't-tell proof
- beat: relief + control
- blueprint: cursor-ui-demo (Adapt)
- sfx: notification-pop, click, whoosh-soft
- asset_candidates:

narrativeRole: Pay off Frame 2 directly — the buried 22-minute prompt becomes a banner you cannot miss, and the click resolves it. The core loop, demonstrated.
keyMessage: Attention routed, one click back to work.

Adapt: keep the cursor-drives-the-UI signature with camera chasing each interaction; the surface is the recreated island + one editor window instead of a full app.
Scene 1 (0.0–2.2s): the collapsed island strip holds top-center on black; on "an agent needs you?", it expands downward (uniform scale-settle) and an event card slides in — orange ⚠ bubble icon, "Claude Code" bold + "api" in orange, "needs your input" dim — `spring-pop-entrance`, smooth; camera pushes gently toward it (`multi-phase-camera`) — Centered on island, ~50%.
Scene 2 (2.2–4.6s): on "the second it happens", a mono latency chip "+0.0s" ticks beside the card and an orange bell + count pulses once on the strip (`asr-keyword-glow`); nothing else moves — the banner is the only bright thing on screen (payoff of Frame 2's buried orange).
Scene 3 (4.6–6.6s): on "click the banner", a custom cursor arcs in and clicks the card (`cursor-click-ripple`), the card depresses (`press-release-spring`).
Scene 4 (6.6–8.0s): on "you're in the right window", zoom-through seam (`cut-catalog.md`, forward) into a flat recreated editor window snapping to front with the same "api" mono label glowing once (`asr-keyword-glow`); settle and hold.

## Frame 6 — The whole fleet

- scene: Expanded island held as hero; session rows tick in — green "working", orange "needs you" capsule sorted to top, dim "idle" — project names in per-project colors
- voiceover: "Every session on your machine — live. Who's working. Who's blocked. Who's done."
- duration: 4.907s
- transition_in: push-slide LEFT
- status: animated
- src: compositions/frames/06-fleet.html
- type: feature_showcase
- persuasion: Show-don't-tell proof
- beat: control + clarity
- blueprint: device-surface-showcase (Adapt)
- sfx: ui-pop, soft-tick
- asset_candidates:

narrativeRole: Scale the single banner into fleet-level command: the dashboard answers the "what's happening behind my windows" anxiety wholesale.
keyMessage: The fleet, at a glance.

Adapt: keep the hero-surface-whose-screens-advance signature (static-tour variant, no 3D hand); the surface is the expanded island, and the "screens advancing" is rows populating on cue.
Scene 1 (0.0–1.8s): the expanded island floats as hero, slightly larger than life — asymmetric 60/40 right, mono caption rail left reading "live sessions" in accent; on "every session on your machine", the empty list panel seats with a scale-settle.
Scene 2 (1.8–4.6s): rows tick in ONE per spoken cue (`dynamic-content-sequencing`): on "who's working" a green-dot row (claude · api — 2h 41m); on "who's blocked" an orange-dot row with a "needs you" capsule that sorts itself to the top with a FLIP-style reorder (smooth, `power3`); on "who's done" a green ✓ done card above.
Scene 3 (4.6–7.0s): a dim idle row (gray dot) completes the picture; left rail cues fade up to full list ("working · blocked · done" mono, each glowing as named — `asr-keyword-glow`); hold the read, subtle jitter only.

## Frame 7 — One click, silence

- scene: The island strip's mic glyph; a cursor clicks it; it flips to red mic-slash and a "Muted" state ripples across app pills (Meet, Slack, Zoom) at once
- voiceover: "The mute button? It's at eye level. One click — every app, muted."
- duration: 3.883s
- transition_in: push-slide LEFT
- status: animated
- src: compositions/frames/07-mute.html
- type: feature_showcase
- persuasion: Friction reduction
- beat: relief + power
- blueprint: cursor-ui-demo (Adapt)
- sfx: click, mute-thunk
- asset_candidates:

narrativeRole: Pay off Frame 3's "are you muted?" — mute state is visible, device-level, and one click. The most universal single feature.
keyMessage: Mic certainty, finally.

Adapt: keep cursor-drives-UI; the workflow is a single click whose consequence fans out — the fan-out is the shot's development.
Scene 1 (0.0–1.8s): tight framing on the collapsed island strip, mic glyph white; on "the mute button?", the glyph gets a marker circle drawn around it (`css-marker-patterns`, accent) — Centered close-up, ~40%.
Scene 2 (1.8–3.4s): on "one click", cursor arcs in, clicks (`cursor-click-ripple` + `press-release-spring`); the glyph flips to red mic-slash on a hard cut.
Scene 3 (3.4–6.0s): on "every app, muted", three flat app pills (meet · slack · zoom, mono labels) reveal in a row beneath and each flips to a red "muted" state in a fast cascade (`dynamic-content-sequencing`), a red hairline connecting them to the island draws on (`svg-path-draw`); hold with the red state reading clean.

## Frame 8 — Only you can see it

- scene: Split screen — "YOUR SCREEN" left shows the teleprompter panel scrolling under the camera; "WHAT THEY SEE" right shows the same desktop, no prompter; badges pop on each side
- voiceover: "And the teleprompter under your camera? Your audience will never see it. Yours — and only yours."
- duration: 6.208s
- transition_in: crossfade
- status: animated
- src: compositions/frames/08-prompter.html
- type: feature_showcase
- persuasion: Show-don't-tell proof
- beat: awe + confidence
- blueprint: comparison-split (Reproduce)
- sfx: whoosh-soft, ui-pop
- asset_candidates:

narrativeRole: The creator-side magic trick and the video's wow beat — capture-invisibility is best proven by literally showing both screens.
keyMessage: A script at the lens, invisible to everyone else.

Scene 1 (0.0–2.4s): on "the teleprompter under your camera?", the LEFT panel enters from the left wing with a mirrored book-open tilt (`split-tilt-cards`): a recreated desktop with the dark-glass prompter panel under the notch, script text visible with the orange reading guide — split-screen, equal weight.
Scene 2 (2.4–4.6s): on "your audience will never see it", the RIGHT panel mirrors in from the right wing: the SAME desktop, prompter conspicuously absent — the emptiness is the reveal; a slow single scroll advances the script text on the left only.
Scene 3 (4.6–7.0s): on "yours — and only yours", the signature inner-edge pill badges spring-pop on each panel — "your screen" (accent) and "what they see" (dim) — then the whole split holds still.

## Frame 9 — Your notch, on duty

- scene: Closing lines snap in beat by beat — "Free." "Open source." — resolving on the wordmark and the GitHub URL held on black
- voiceover: "Free. Open source. NotchControls — your notch, on duty."
- duration: 4.16s
- transition_in: zoom-through
- status: animated
- src: compositions/frames/09-cta.html
- type: cta
- persuasion: Risk reversal
- beat: motivation + peace of mind
- blueprint: kinetic-type-beats (Reproduce)
- sfx: ui-pop, impact-soft
- asset_candidates:

narrativeRole: Close the loop with zero-risk framing (free, MIT) and one action: the URL. Tagline echoes the message.
keyMessage: github.com/pratiksardar/di-contorls — go get it.

Scene 1 (0.0–2.0s): "free." lands alone center as display 900 via hard cut (`discrete-text-sequence`); on the next cue "open source." replaces it the same way — the swap is the rhythm; ink-black field, Centered ~45%.
Scene 2 (2.0–4.0s): on "NotchControls", the wordmark lands with a kinetic beat-slam finale (`kinetic-beat-slam`, smooth settles) with the tiny island glyph (black pill, orange mic dot) seating above it.
Scene 3 (4.0–6.0s): on "your notch, on duty", the tagline fades up mono at 60% beneath, then the URL github.com/pratiksardar/di-contorls types on behind a caret (`discrete-text-sequence` + `context-sensitive-cursor`) in accent orange; final still hold ~1.5s.
