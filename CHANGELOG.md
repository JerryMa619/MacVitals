# Changelog

All notable MacVitals changes are summarized here.

## Unreleased

### Added

- Native SwiftUI + AppKit macOS app target with a menu bar monitor and debug-visible Dock mode.
- Real-time dashboard for memory pressure, CPU, disk, battery, network throughput, and high-memory apps.
- Memory, CPU, and swap trend charts.
- Dedicated Settings window for menu bar display mode, sampling mode, alerts, launch at login, privacy guide access, and a visible quit action.
- Configurable sampling modes: Balanced, Low Power, and Live.
- Faster visible refresh behavior for the dashboard and menu bar monitor, including a warmup sample shortly after launch.
- Local threshold notifications for high memory pressure and swap usage.
- Explainable recommendations for memory pressure, swap, CPU load, and low disk space.
- Local diagnostic snapshot copy for troubleshooting.
- First-launch privacy guide explaining local monitoring, no analytics/upload, and user-controlled actions.
- App icon, sandbox entitlement, launch-at-login support, and App Store checklist.
- Thermal status monitoring through Apple's public `ProcessInfo.thermalState` API.
- Language picker with System, English, Simplified Chinese, French, Russian, and German options.
- Lightweight health diagnostics derived from existing stats and the short in-memory history window.

### Changed

- Made the debug build visible in Dock and Command-Tab so the app can be inspected during development.
- Expanded the menu bar label from a short `MV` style to a clearer `MacVitals` status label.
- Moved preferences out of the dashboard and into a separate settings window.
- Reworked the dashboard into a darker futuristic interface with larger glowing rings, larger trend charts, denser telemetry, and accent-aware controls.
- Enlarged the primary memory ring and trend chart presentation to make the app feel more like a live system console.
- Added a richer menu bar mini dashboard with CPU, thermal, disk, memory pressure trend, and top insight summaries.
- Disabled Xcode's debug dynamic library injection for the project to avoid blank windows when launching the debug `.app` directly.
- Diagnostic snapshots now include the derived health score, pressure trend, bottleneck, and power load summary.

### Notes

- MacVitals intentionally avoids private sensor APIs, automatic process killing, and misleading cleanup claims.
- The thermal readout is a system thermal state, not a private mainboard temperature in degrees Celsius.
- The production App Store build can switch back to a pure menu-bar agent after development review is comfortable.

## Development Timeline

### Foundation

- Created the initial MacVitals project as a native macOS SwiftUI/AppKit app.
- Added memory monitoring as the first core scenario, focused on detecting pressure caused by many open pages and apps.
- Added CPU, disk, battery, network, swap, and high-memory process visibility.
- Added conservative optimization guidance that opens Activity Monitor instead of force-killing processes.
- Added App Sandbox entitlement and an App Store-oriented checklist.

### Visibility And Debugging

- Made the debug build easier to find from Dock and Command-Tab during development.
- Improved the launch path so the main dashboard can reopen reliably.
- Fixed the blank dashboard issue seen when launching the built `.app` directly.
- Added first-launch privacy guidance so users understand MacVitals runs locally.

### Settings And Controls

- Added a dedicated Settings window.
- Added menu bar display mode settings.
- Added sampling mode controls for responsiveness and power usage.
- Added alert threshold controls.
- Added Launch at Login support through Apple's public ServiceManagement API.
- Added a visible quit button in Settings.

### Interface Iterations

- Replaced the early utilitarian UI with a darker, more polished sci-fi visual direction.
- Added larger circular vitals, larger trend charts, neon-style accents, and a more legible data layout.
- Added system-accent-aware controls where appropriate.
- Improved the menu bar popover into a compact mini dashboard rather than a plain status panel.

### Localization And Hardware Status

- Added localization resources for English, Simplified Chinese, French, Russian, and German.
- Added a language picker with a System Default option.
- Added thermal state monitoring using public Apple APIs.
- Documented that private sensor temperature readings are intentionally avoided for App Store safety.

### Low-Overhead Diagnostics

- Added a health score that blends memory pressure, swap, CPU, disk pressure, and thermal state.
- Added short-window pressure trend detection without increasing the stored history size.
- Added likely bottleneck detection for memory, CPU, disk space, or thermal pressure.
- Added a lightweight power-load estimate based on CPU, thermal state, and network activity.
- Kept diagnostics derived from already-collected samples to avoid adding persistent memory overhead.

### GitHub And Release Preparation

- Published the repository to GitHub under `JerryMa619/MacVitals`.
- Set the GitHub repository visibility to public.
- Kept iterative commits pushed to `main`.
- Added project documentation, roadmap notes, development notes, and App Store checklist materials.
