// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "swift-composable-architecture",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "ComposableArchitecture",
      targets: ["ComposableArchitecture"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.13.0"),
    .package(url: "https://github.com/google/swift-benchmark", from: "0.1.0"),
    // currently produces a warning in SPM, but overrrides `Depdendencies`'s version with a version
    // that supports Windows via OpenCombine(Shims) (to fix warning, see thebrowsercompany/swift-dependencies below)
    .package(url: "https://github.com/thebrowsercompany/combine-schedulers", branch: "develop"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.2"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
    // here to also link to https://github.com/thebrowsercompany/combine-schedulers, which supports OpenCombine
    .package(url: "https://github.com/thebrowsercompany/swift-dependencies", branch: "develop"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.7.0"),
    .package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "ComposableArchitecture",
      dependencies: [
        .product(name: "OpenCombineShim", package: "OpenCombine"),
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
        .product(name: "OrderedCollections", package: "swift-collections"),
        .product(name: "SwiftUINavigationCore",
          package: "swiftui-navigation",
          condition: .when(platforms: [.macOS, .iOS, .tvOS, .macCatalyst, .watchOS])),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
      ],
      exclude: osSpecificComposableArchitectureExcludes()
    ),
    .testTarget(
      name: "ComposableArchitectureTests",
      dependencies: [
        "_CAsyncSupport",
        "ComposableArchitecture",
      ]
    ),
    .executableTarget(
      name: "swift-composable-architecture-benchmark",
      dependencies: [
        "ComposableArchitecture",
        .product(name: "Benchmark", package: "swift-benchmark"),
      ]
    ),
    .systemLibrary(name: "_CAsyncSupport"),
  ]
)

func osSpecificComposableArchitectureExcludes() -> [String] {
#if os(Windows)
    return [
        "SwiftUI",
        "UIKit/AlertStateUIKit.swift",
        "Reducer/AnyReducer/AnyReducerBinding.swift",
        "Reducer/Reducers/BindingReducer.swift",
        "Reducer/Reducers/SignpostReducer.swift",
        "Internal/Deprecations.swift",
        "Effects/Animation.swift",
        "Internal/Binding+IsPresent.swift",
    ]
#else
    return []
#endif
}

//for target in package.targets {
//  target.swiftSettings = target.swiftSettings ?? []
//  target.swiftSettings?.append(
//    .unsafeFlags([
//      "-Xfrontend", "-warn-concurrency",
//      "-Xfrontend", "-enable-actor-data-race-checks",
//      "-enable-library-evolution",
//    ])
//  )
//}
