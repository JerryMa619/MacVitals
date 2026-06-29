# Changelog

All notable MacVitals changes are summarized here.

## Unreleased

### Added

- Native SwiftUI + AppKit macOS app target with a menu bar monitor and debug-visible Dock mode.
- Real-time dashboard for memory pressure, CPU, disk, battery, network throughput, and high-memory apps.
- Memory, CPU, and swap trend charts.
- Dedicated Settings window for menu bar display mode, sampling mode, alerts, launch at login, and privacy guide access.
- Configurable sampling modes: Balanced, Low Power, and Live.
- Local threshold notifications for high memory pressure and swap usage.
- Explainable recommendations for memory pressure, swap, CPU load, and low disk space.
- Local diagnostic snapshot copy for troubleshooting.
- First-launch privacy guide explaining local monitoring, no analytics/upload, and user-controlled actions.
- English and Simplified Chinese localization resources.
- App icon, sandbox entitlement, launch-at-login support, and App Store checklist.

### Changed

- Made the debug build visible in Dock and Command-Tab so the app can be inspected during development.
- Expanded the menu bar label from a short `MV` style to a clearer `MacVitals` status label.
- Moved preferences out of the dashboard and into a separate settings window.

### Notes

- MacVitals intentionally avoids private sensor APIs, automatic process killing, and misleading cleanup claims.
- The production App Store build can switch back to a pure menu-bar agent after development review is comfortable.
