<img src="./Logo.png" width="128">

# Afterburner

`Afterburner` aims to build UIKit components in SwiftUI.

> Built for performance and backwards compatibility using [Engine](https://github.com/nathantannar4/Engine)

## See Also

- [Ignition](https://github.com/nathantannar4/Ignition)
- [Turbocharger](https://github.com/nathantannar4/Turbocharger)
- [Transmission](https://github.com/nathantannar4/Transmission)

## Requirements

- Deployment target: iOS 13.0, macOS 10.15, tvOS 13.0, or watchOS 6.0
- Xcode 15+

## Installation

### Xcode Projects

Select `File` -> `Swift Packages` -> `Add Package Dependency` and enter `https://github.com/nathantannar4/Afterburner`.

### Swift Package Manager Projects

You can add `Afterburner` as a package dependency in your `Package.swift` file:

```swift
let package = Package(
    //...
    dependencies: [
        .package(url: "https://github.com/nathantannar4/Afterburner"),
    ],
    targets: [
        .target(
            name: "YourPackageTarget",
            dependencies: [
                .product(name: "Afterburner", package: "Afterburner"),
            ],
            //...
        ),
        //...
    ],
    //...
)
```

### Xcode Cloud / Github Actions / Fastlane / CI

[Engine](https://github.com/nathantannar4/Engine) includes a Swift macro, which requires user validation to enable or the build will fail. When configuring your CI, pass the flag `-skipMacroValidation` to `xcodebuild` to fix this.
