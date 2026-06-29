# MacVitals

MacVitals is a lightweight native macOS menu bar monitor for memory, CPU, disk, battery, network, and high-memory apps.

## Current Scope

- Native Swift + SwiftUI + AppKit menu bar app.
- Low-overhead periodic sampling.
- Memory pressure, swap, CPU, disk, battery, network throughput, and running app memory ranking.
- Dedicated Settings window for preferences and alert thresholds.
- App Sandbox entitlement and menu bar agent bundle configuration.
- Launch at Login preference using Apple's public ServiceManagement API.
- Menu bar display modes: memory pressure, used memory, CPU, or compact.
- Local threshold notifications for high memory pressure and high swap usage.
- Short in-memory trend charts for memory pressure, CPU, and swap.
- Local diagnostic snapshot copy for troubleshooting.
- English and Simplified Chinese localization resources.
- Conservative "optimize" action that surfaces heavy apps and opens Activity Monitor instead of force-killing processes.

## Run

Open `MacVitals.xcodeproj` in Xcode and run the `MacVitals` scheme.

Command-line debug app build:

```sh
xcodebuild \
  -project MacVitals.xcodeproj \
  -scheme MacVitals \
  -configuration Debug \
  -derivedDataPath ../../work/MacVitalsDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## App Store Direction

Keep MacVitals focused on monitoring, diagnosis, and transparent recommendations. Avoid private APIs, misleading cleanup claims, background process killing, or fake "memory freed" numbers.
