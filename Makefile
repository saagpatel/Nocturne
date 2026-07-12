.PHONY: generate build test release archive clean

PROJECT := Nocturne.xcodeproj
SCHEME := Nocturne
SIMULATOR ?= platform=iOS Simulator,name=iPhone 17 Pro

generate:
	test -f Config.xcconfig || cp Config.xcconfig.example Config.xcconfig
	test -f Nocturne/Resources/gaia_dr3.sqlite
	xcodegen generate

build: generate
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -destination '$(SIMULATOR)' CODE_SIGNING_ALLOWED=NO

test: generate
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination '$(SIMULATOR)' CODE_SIGNING_ALLOWED=NO

release: generate
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO

archive: generate
	xcodebuild archive -project $(PROJECT) -scheme $(SCHEME) -configuration Release -destination 'generic/platform=iOS' -archivePath build/Nocturne.xcarchive CODE_SIGNING_ALLOWED=NO

clean:
	rm -rf build
	xcodebuild clean -project $(PROJECT) -scheme $(SCHEME)
