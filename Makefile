PROJECT := NetworkMenuBar.xcodeproj
SCHEME := NetworkMenuBar
DERIVED := build
APP_NAME := Network Menu Bar.app
APP := $(DERIVED)/Build/Products/Release/$(APP_NAME)
VERSION := $(shell sed -n 's/^ *MARKETING_VERSION: "\([^"]*\)".*/\1/p' project.yml)
DMG := dist/Network-Menu-Bar-$(VERSION).dmg
STAGE := $(DERIVED)/dmg
RW_DMG := $(DERIVED)/dmg-rw.dmg

.PHONY: generate build test run release clean

generate:
	xcodegen generate --quiet

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -derivedDataPath $(DERIVED) build

test:
	swift test --package-path NetworkMenuBarKit

run: build
	open "$(APP)"

release: build
	codesign --force --options runtime --sign - "$(APP)"
	codesign --verify --strict --verbose=2 "$(APP)"
	rm -rf "$(STAGE)" && mkdir -p "$(STAGE)" dist
	ditto "$(APP)" "$(STAGE)/$(APP_NAME)"
	ln -s /Applications "$(STAGE)/Applications"
	cp "$(APP)/Contents/Resources/AppIcon.icns" "$(STAGE)/.VolumeIcon.icns"
# hdiutil sometimes fails with "Resource busy" on CI runners
	for i in 1 2 3; do hdiutil create -volname "Network Menu Bar" -srcfolder "$(STAGE)" -format UDRW -ov "$(RW_DMG)" && break; sleep 5; done
# -srcfolder drops the volume's custom-icon flag, so it is set on the mounted read-write image
	mount="$$(hdiutil attach -nobrowse -noautoopen "$(RW_DMG)" | awk -F'\t' '/\/Volumes\//{print $$NF}')" && \
		SetFile -a C "$$mount" && \
		for i in 1 2 3; do hdiutil detach "$$mount" && break; sleep 5; done
	hdiutil convert "$(RW_DMG)" -format UDZO -ov -o "$(DMG)"
	rm -f "$(RW_DMG)"
	test -f "$(DMG)"
	cd dist && shasum -a 256 "$(notdir $(DMG))" > "$(notdir $(DMG)).sha256"
	@echo "Created $(DMG) and $(DMG).sha256"

clean:
	rm -rf $(DERIVED) $(PROJECT) dist
