# Distributing NotchControls

## Local build & release artifact

```bash
make release   # → build/NotchControls-<version>.zip (ad-hoc signed)
```

## Shipping checklist (per release)

1. Bump `VERSION` in the Makefile and `CFBundleShortVersionString`/`CFBundleVersion` in `Resources/Info.plist` (+ the version shown in Settings).
2. `make release`, smoke-test the zip on a clean user account: island appears, `install-hooks` works, prompter opens.
3. Tag: `git tag v<version> && git push --tags`.
4. Create a GitHub Release, attach the zip, paste highlights from ROADMAP.md.

## Gatekeeper reality (ad-hoc signed builds)

The zip is ad-hoc signed. Users who download it must either right-click → Open
the first launch, or run:

```bash
xattr -d com.apple.quarantine /Applications/NotchControls.app
```

Put this in the release notes until proper signing lands.

## Proper signing + notarization (when a Developer ID is available, $99/yr)

```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: NAME (TEAMID)" build/NotchControls.app
ditto -c -k --keepParent build/NotchControls.app build/NotchControls.zip
xcrun notarytool submit build/NotchControls.zip \
  --apple-id you@example.com --team-id TEAMID --password <app-specific> --wait
xcrun stapler staple build/NotchControls.app
```

Note: `SMAppService` launch-at-login and hooks work fine ad-hoc; notarization
only removes the Gatekeeper friction.

## Homebrew cask (after the repo is public with at least one release)

Submit to homebrew/cask or host a personal tap:

```ruby
cask "notchcontrols" do
  version "0.2.0"
  sha256 "<shasum -a 256 of the zip>"
  url "https://github.com/<owner>/notchcontrols/releases/download/v#{version}/NotchControls-#{version}.zip"
  name "NotchControls"
  desc "Notch cockpit: system-wide mic mute, agent notifications, capture-invisible teleprompter"
  homepage "https://github.com/<owner>/notchcontrols"
  depends_on macos: ">= :sonoma"
  app "NotchControls.app"
end
```

Personal tap route: create `<owner>/homebrew-tap` repo, add the cask under
`Casks/`, then users run `brew install <owner>/tap/notchcontrols`.

## Publishing the repo

```bash
gh repo create notchcontrols --public --source . --push
```

Launch surfaces (from ROADMAP.md): Show HN, r/ClaudeAI, r/macapps, an
awesome-claude-code PR, and demo GIFs of the two killer moments — muting
mid-Meet, and banner→click→editor.
