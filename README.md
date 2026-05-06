# Quick Cards

Quick Cards is a minimal native macOS 26 notes app with local card storage, system-driven Liquid Glass-style appearance, first-line card titles, per-line done toggles, rich-text quick capture, a stopwatch that appears live in the menu bar while running, an expanded cards window, and a WidgetKit control for Quick Note access on supported macOS versions.

## Build

```sh
xcodebuild -project QuickCards.xcodeproj -scheme QuickCards -destination 'platform=macOS' build
```

## Test

```sh
xcodebuild -project QuickCards.xcodeproj -scheme QuickCards -destination 'platform=macOS' test
```
