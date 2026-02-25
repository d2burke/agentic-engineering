.PHONY: build test lint format clean test-unit test-module

# Build all targets
build:
	swift build

# Run all tests
test:
	swift test

# Run tests for a specific module (usage: make test-module MODULE=ModelsTests)
test-module:
	swift test --filter $(MODULE)

# Lint checks
lint:
	swiftlint lint --strict
	swiftformat --lint .

# Auto-format code
format:
	swiftformat .

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build

# Resolve package dependencies
resolve:
	swift package resolve

# Generate Xcode project
xcode:
	open Package.swift
