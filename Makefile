APP_NAME = NotchControls
VERSION  = 0.3.0
BUNDLE   = build/$(APP_NAME).app
BINARY   = .build/release/$(APP_NAME)

.PHONY: build bundle run dev release clean

build:
	swift build -c release

bundle: build
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	cp Resources/Info.plist $(BUNDLE)/Contents/
	cp Resources/AppIcon.icns $(BUNDLE)/Contents/Resources/
	cp $(BINARY) $(BUNDLE)/Contents/MacOS/
	codesign --force --sign - $(BUNDLE)

run: bundle
	open $(BUNDLE)

dev:
	swift run

# zip for GitHub Releases; see docs/DISTRIBUTION.md for signing/notarization
release: bundle
	ditto -c -k --keepParent $(BUNDLE) build/$(APP_NAME)-$(VERSION).zip
	@echo "release: build/$(APP_NAME)-$(VERSION).zip"

clean:
	rm -rf .build build
