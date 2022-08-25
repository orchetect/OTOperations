// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "OTOperations",
    
    platforms: [
        .macOS(.v10_11), .iOS(.v9), .tvOS(.v9), .watchOS(.v2)
    ],
    
    products: [
        .library(
            name: "OTOperations",
            targets: ["OTOperations"]
        )
    ],
    
    dependencies: [
        .package(url: "https://github.com/orchetect/OTAtomics", from: "1.0.0"),
        
        // testing-only:
        .package(url: "https://github.com/orchetect/XCTestUtils", from: "1.0.1")
    ],
    
    targets: [
        .target(
            name: "OTOperations",
            dependencies: ["OTAtomics"]
        ),
        .testTarget(
            name: "OTOperationsTests",
            dependencies: ["OTOperations", "XCTestUtils"]
        )
    ]
)

func addShouldTestFlag() {
    package.targets.filter { $0.isTest }.forEach { target in
        if target.swiftSettings == nil { target.swiftSettings = [] }
        target.swiftSettings?.append(.define("shouldTestCurrentPlatform"))
    }
}

// Xcode 12.5.1 (Swift 5.4.2) introduced watchOS testing
#if swift(>=5.4.2)
addShouldTestFlag()
#elseif !os(watchOS)
addShouldTestFlag()
#endif
