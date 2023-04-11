<img src="./Logo.png" width="128">

# Afterburner

`Afterburner` aims to build UIKit components in SwiftUI.

> Built for performance and backwards compatibility using [Engine](https://github.com/nathantannar4/Engine)

## Requirements

- Deployment target: iOS 13.0, macOS 10.15, tvOS 13.0, or watchOS 6.0
- Xcode 14.1+

## Installation

### Xcode Projects

Select `File` -> `Swift Packages` -> `Add Package Dependency` and enter `https://github.com/nathantannar4/Turbocharger`.

### Swift Package Manager Projects

You can add `Turbocharger` as a package dependency in your `Package.swift` file:

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
