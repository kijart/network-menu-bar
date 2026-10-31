PROJECT := NetworkMenuBar.xcodeproj
SCHEME := NetworkMenuBar
DERIVED := build
APP := $(DERIVED)/Build/Products/Release/Network Menu Bar.app
VERSION := $(shell sed -n 's/^ *MARKETING_VERSION: "\(.*\)"/\1/p' project.yml)
ZIP := dist/Network-Menu-Bar-$(VERSION).zip

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
	codesign --force --deep --options runtime --sign - "$(APP)"
	codesign --verify --strict --verbose=2 "$(APP)"
	mkdir -p dist
	ditto -c -k --keepParent "$(APP)" "$(ZIP)"
	@echo "Created $(ZIP)"

clean:
	rm -rf $(DERIVED) $(PROJECT) dist
