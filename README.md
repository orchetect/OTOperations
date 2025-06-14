# OTOperations

[![CI Build Status](https://github.com/orchetect/OTOperations/actions/workflows/build.yml/badge.svg)](https://github.com/orchetect/OTOperations/actions/workflows/build.yml) [![Platforms - macOS 10.15+ | iOS 13+ | tvOS 13+ | watchOS 6+ | visionOS 1+](https://img.shields.io/badge/platforms-macOS%2010.15+%20|%20iOS%2013+%20|%20tvOS%2013+%20|%20watchOS%206+%20|%20visionOS%201+-lightgrey.svg?style=flat)](https://developer.apple.com/swift) ![Swift 5.3-6.0](https://img.shields.io/badge/Swift-5.3–6.0-orange.svg?style=flat) [![Xcode 15-16](https://img.shields.io/badge/Xcode-15–16-blue.svg?style=flat)](https://developer.apple.com/swift) [![License: MIT](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/orchetect/OTOperations/blob/main/LICENSE)

Useful `NSOperation` (`Operation`) and `NSOperationQueue` (`OperationQueue`) subclasses for Swift.

Scalable, thread-safe, and automatically fully progress-reporting for nested child operations.

- Foundational
  - `BasicOperation` and `BasicAsyncOperation`
- Closure-based
  - `ClosureOperation` and `AsyncClosureOperation`
  - `InteractiveClosureOperation` and `InteractiveAsyncClosureOperation`
- Thread-safe atomic mutability
  - `AtomicBlockOperation`

## Installation: Swift Package Manager (SPM)

### Dependency within an Application

1. Add the package to your Xcode project using Swift Package Manager
   - Select File → Swift Packages → Add Package Dependency
   - Add package using  `https://github.com/orchetect/OTOperations` as the URL.
2. Import the module in your *.swift files where needed.
   ```swift
   import OTOperations
   ```

### Dependency within a Swift Package

1. In your Package.swift file:

   ```swift
   dependencies: [
       .package(url: "https://github.com/orchetect/OTOperations", from: "2.0.0")
   ],
   ```
   
2. Using `internal import` prevents the methods and properties in `OTOperations` from being exported to the consumer of your SPM package.

   ```swift
   internal import OTOperations
   ```

## Documentation

Most methods are implemented as category methods so they are generally discoverable.

All methods have inline help explaining their purpose and basic usage examples.

## Author

Coded by a bunch of 🐹 hamsters in a trenchcoat that calls itself [@orchetect](https://github.com/orchetect).

## License

Licensed under the MIT license. See [LICENSE](https://github.com/orchetect/OTOperations/blob/master/LICENSE) for details.

## Community & Support

Please do not email maintainers for technical support. Several options are available for issues and questions:

- Questions and feature ideas can be posted to [Discussions](https://github.com/orchetect/OTOperations/discussions).
- If an issue is a verifiable bug with reproducible steps it may be posted in [Issues](https://github.com/orchetect/OTOperations/issues).

## Contributions

Contributions are welcome. Posting in [Discussions](https://github.com/orchetect/OTOperations/discussions) first prior to new submitting PRs for features or modifications is encouraged.
