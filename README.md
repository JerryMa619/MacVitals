# MacVitals

MacVitals is a lightweight native macOS menu bar monitor for memory, CPU, disk, battery, network, and high-memory apps.

## Current Scope

- Native Swift + SwiftUI + AppKit menu bar app.
- Low-overhead periodic sampling.
- Memory pressure, swap, CPU, disk, battery, network throughput, and running app memory ranking.
- Conservative "optimize" action that surfaces heavy apps and opens Activity Monitor instead of force-killing processes.

## Run

Open `Package.swift` in Xcode and run the `MacVitals` executable target.

The current machine has only Command Line Tools selected, so full `xcodebuild` verification requires installing or selecting full Xcode:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## App Store Direction

Keep MacVitals focused on monitoring, diagnosis, and transparent recommendations. Avoid private APIs, misleading cleanup claims, background process killing, or fake "memory freed" numbers.
