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
    // TODO: windows - this didn't build in VSCode initially
    // .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.13.0"),
    .package(url: "https://github.com/google/swift-benchmark", from: "0.1.0"),
    .package(url: "https://github.com/pointfreeco/combine-schedulers", from: "0.8.0"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.14.0"),
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.2"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.9.1"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.2.0"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "0.7.0"),
    .package(url: "https://github.com/pointfreeco/swiftui-navigation", from: "0.7.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.5.0"),
  ],
  targets: [
    .target(
      name: "ComposableArchitecture",
      dependencies: [
        "Dependencies",
        .product(name: "OpenCombineShim", package: "OpenCombine"),
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
        .product(name: "OrderedCollections", package: "swift-collections"),
        .product(name: "_SwiftUINavigationState", package: "swiftui-navigation"),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
      ],
      exclude: composableArchitectureExcludes()
    ),
    .testTarget(
      name: "ComposableArchitectureTests",
      dependencies: [
        "_CAsyncSupport",
        "ComposableArchitecture"
      ],
      exclude: composableArchitectureTestsExcludes()
    ),
    .target(
      name: "Dependencies",
      dependencies: [
        .product(name: "Clocks", package: "swift-clocks"),
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
      ]
    ),
    .testTarget(
      name: "DependenciesTests",
      dependencies: [
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

func composableArchitectureExcludes() -> [String] {
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

func composableArchitectureTestsExcludes() -> [String] {
#if os(Windows)
    return [
        "TimerTests.swift", // no timer in OpenCombine
        "DebugTests.swift",
        "BindingTests.swift", // no SwiftUI
        "DeprecatedTests.swift",
        "EffectTests.swift",
        "EffectThrottleTests.swift",
        "EffectDebounceTests.swift",
        "EffectDeferredTests.swift",
        "RuntimeWarningTests.swift", // no SwiftUI
        "WithViewStoreTests.swift", // no SwiftUI
        "WithViewStoreAppTest.swift", // no SwiftUI
        "TestStoreTests.swift",
    ]
#else
    return [
        "TimerTests.swift",
    ]
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
