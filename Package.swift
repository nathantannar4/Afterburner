// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Afterburner",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "Afterburner",
            targets: ["Afterburner"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nathantannar4/Engine", from: "1.0.0"),
        .package(url: "https://github.com/nathantannar4/Turbocharger", from: "1.0.0"),
        .package(url: "https://github.com/nathantannar4/Transmission", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Afterburner",
            dependencies: [
                "Engine",
                "Turbocharger",
                "Transmission",
            ]
        )
    ]
)
