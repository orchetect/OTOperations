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
        .package(url: "https://github.com/orchetect/OTAtomics", from: "1.0.1"),
        
        // testing-only:
        .package(url: "https://github.com/orchetect/XCTestUtils", from: "1.0.3")
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
