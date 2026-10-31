PROJECT := NetworkMenuBar.xcodeproj
SCHEME := NetworkMenuBar
DERIVED := build
APP := $(DERIVED)/Build/Products/Release/Network Menu Bar.app

.PHONY: generate build test run clean

generate:
	xcodegen generate --quiet

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -derivedDataPath $(DERIVED) build

test:
	swift test --package-path NetworkMenuBarKit

run: build
	open "$(APP)"

clean:
	rm -rf $(DERIVED) $(PROJECT)
