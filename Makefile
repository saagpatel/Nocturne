.PHONY: build test clean run

build:
	swift build

test:
	swift test

run:
	swift run

clean:
	rm -rf .build
