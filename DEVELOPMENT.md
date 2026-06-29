# Development Notes

## Architecture

- `MacVitalsApp.swift`: AppKit menu bar shell and SwiftUI popover hosting.
- `SystemMonitor.swift`: periodic sampling coordinator and macOS system API bridge.
- `LaunchAtLoginController.swift`: ServiceManagement wrapper for the Launch at Login preference.
- `DashboardView.swift`: compact SwiftUI status panel.
- `Models.swift`: value models for sampled hardware and process data.
- `Formatters.swift`: display helpers.
- `MacVitals.xcodeproj`: macOS App target with App Sandbox, app icon, bundle metadata, and shared scheme.

## Sampling Strategy

The monitor samples every 4 seconds in the background and every 1.5 seconds while the popover is open. This keeps the menu bar responsive without constantly waking the system.

## Verification Performed

This repository builds with full Xcode selected:

```sh
xcodebuild \
  -project MacVitals.xcodeproj \
  -scheme MacVitals \
  -configuration Debug \
  -derivedDataPath /Users/zhenyaoma/Documents/Codex/2026-06-29/ni-h/work/MacVitalsDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

The Swift Package target also builds:

```sh
env HOME=/Users/zhenyaoma/Documents/Codex/2026-06-29/ni-h/work/swift-home \
  CLANG_MODULE_CACHE_PATH=/Users/zhenyaoma/Documents/Codex/2026-06-29/ni-h/work/swift-home/.cache/clang/ModuleCache \
  SWIFTPM_CACHE_PATH=/Users/zhenyaoma/Documents/Codex/2026-06-29/ni-h/work/swiftpm-cache \
  SWIFTPM_CONFIG_PATH=/Users/zhenyaoma/Documents/Codex/2026-06-29/ni-h/work/swiftpm-config \
  SWIFTPM_SECURITY_PATH=/Users/zhenyaoma/Documents/Codex/2026-06-29/ni-h/work/swiftpm-security \
  swift build
```

The environment variables above are only needed in restricted Codex sessions where the default SwiftPM cache directories are not writable.

Earlier syntax/API checking was performed with:

```sh
env CLANG_MODULE_CACHE_PATH=/Users/zhenyaoma/Documents/Codex/2026-06-29/ni-h/work/clang-module-cache \
  xcrun swiftc -parse-as-library -target arm64-apple-macosx14.0 \
  -framework AppKit -framework SwiftUI -framework IOKit \
  Sources/MacVitals/*.swift -o /tmp/MacVitalsCheck
```
