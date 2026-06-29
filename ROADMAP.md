# MacVitals Roadmap

## 0.1 Prototype

- Menu bar memory pressure indicator.
- Popover dashboard for memory, CPU, disk, battery, network, and heavy apps.
- Manual refresh and Activity Monitor handoff.
- Public API only.

## 0.2 Usability

- Native Xcode macOS app project.
- App icon and menu bar agent bundle metadata.
- Launch at Login preference.
- Dedicated settings window.
- User preferences for menu bar display: memory pressure, used memory, CPU, or compact.
- Notification thresholds for memory pressure and swap.
- Dark and light appearance QA.
- Localized Chinese and English UI.

## 0.3 Diagnostics

- Per-app recommendations when memory pressure and swap both rise.
- Short historical charts for memory, CPU, and swap.
- Low-power, balanced, and live sampling modes.
- Export diagnostic snapshot as plain text.

## 1.0 App Store Candidate

- App sandbox enabled in a full Xcode app target.
- No private APIs.
- No forced process killing.
- No misleading cleanup claims.
- Privacy nutrition labels: no collection by default.
- Signed, notarized, archived, and tested on Apple silicon and Intel Macs if supported.

## Public API Limits

Some hardware details, especially fan speed, SMC temperature sensors, GPU counters, and deep per-process energy metrics, are not reliably available through App Store-safe public APIs. MacVitals should prefer trustworthy public metrics over fragile private sensor access.
