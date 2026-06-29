# MacVitals

MacVitals is a lightweight native macOS menu bar monitor for memory, CPU, disk, battery, network, and high-memory apps.

Website: [MacVitals GitHub Pages](https://jerryma619.github.io/MacVitals/)

Early access: [Join the TestFlight list](https://github.com/JerryMa619/MacVitals/issues/new?title=MacVitals%20Early%20Access%20Request&body=Hi%2C%20I%20would%20like%20to%20join%20the%20MacVitals%20early%20access%20%2F%20TestFlight%20list.)

## Current Scope

- Native Swift + SwiftUI + AppKit menu bar app.
- Low-overhead periodic sampling.
- Memory pressure, swap, CPU, disk, battery, network throughput, thermal state, and running app memory ranking.
- First-launch privacy guide explaining local monitoring and user-controlled actions.
- Dedicated Settings window for preferences and alert thresholds.
- Sampling modes for balanced, low-power, or more responsive updates.
- App Sandbox entitlement and menu bar agent bundle configuration.
- Launch at Login preference using Apple's public ServiceManagement API.
- Menu bar display modes: memory pressure, used memory, CPU, or compact.
- Local threshold notifications for high memory pressure and high swap usage.
- Short in-memory trend charts for memory pressure, CPU, and swap.
- Explainable recommendations for high memory pressure, swap, CPU, and disk constraints.
- Lightweight health diagnostics derived from existing samples: health score, pressure trend, likely bottleneck, and power load.
- Local diagnostic snapshot copy for troubleshooting.
- Language picker with System, English, Simplified Chinese, French, Russian, and German options.
- Futuristic dark dashboard with enlarged rings, trend charts, and a compact menu bar mini dashboard.
- Conservative "optimize" action that surfaces heavy apps and opens Activity Monitor instead of force-killing processes.

See [CHANGELOG.md](CHANGELOG.md) for the development history.
See [ANALYTICS.md](ANALYTICS.md) for the privacy-first analytics plan.

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
