# OTOperations

[![CI Build Status](https://github.com/orchetect/OTOperations/actions/workflows/build.yml/badge.svg)](https://github.com/orchetect/OTOperations/actions/workflows/build.yml) [![Platforms - macOS | iOS | tvOS | watchOS](https://img.shields.io/badge/platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20-lightgrey.svg?style=flat)](https://developer.apple.com/swift) [![License: MIT](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/orchetect/OTOperations/blob/main/LICENSE)

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
       .package(url: "https://github.com/orchetect/OTOperations", from: "1.0.0")
   ],
   ```
   
2. `@_implementationOnly` prevents the methods and properties in `OTOperations` from being exported to the consumer of your SPM package.

   ```swift
   @_implementationOnly import OTOperations
   ```

## Documentation

Most methods are implemented as category methods so they are generally discoverable.

All methods have inline help explaining their purpose and basic usage examples.

## Author

Coded by a bunch of 🐹 hamsters in a trenchcoat that calls itself [@orchetect](https://github.com/orchetect).

## License

Licensed under the MIT license. See [LICENSE](https://github.com/orchetect/OTOperations/blob/master/LICENSE) for details.

## Contributions

Bug fixes and improvements are welcome. Please open an issue to discuss prior to submitting PRs.
