// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "OTOperations",
    
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
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
        .package(url: "https://github.com/orchetect/XCTestUtils", from: "1.1.2")
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
