// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "lingyao-tauri-mobile-platform",
  // The application sets the real iOS 16 deployment target. Keep this package
  // compatible with SwiftPM's 5.3 manifest API, matching Tauri's iOS plugins.
  platforms: [.iOS(.v13)],
  products: [
    .library(
      name: "lingyao-tauri-mobile-platform",
      type: .static,
      targets: ["lingyao-tauri-mobile-platform"])
  ],
  dependencies: [
    .package(name: "Tauri", path: "../.tauri/tauri-api")
  ],
  targets: [
    .target(
      name: "lingyao-tauri-mobile-platform",
      dependencies: [.byName(name: "Tauri")],
      path: "Sources")
  ]
)
