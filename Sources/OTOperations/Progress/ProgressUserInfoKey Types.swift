//
//  ProgressUserInfoKey Types.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if canImport(Foundation)

import Foundation

extension ProgressUserInfoKey {
    
    /// Key: Label for the individual progress instance itself.
    ///
    /// Only applicable to `BasicOperation` and its subclasses.
    internal static let label: Self = .init(rawValue: "label")
    
    /// Key: Label for the progress instance and its direct children only.
    ///
    /// Only applicable to `BasicOperation` and its subclasses.
    internal static let combinedLabel: Self = .init(rawValue: "combinedLabel")
    
    /// Key: Cache for storing the labels of direct children only.
    ///
    /// Only applicable to `BasicOperation` and its subclasses.
    internal static let childLabels: Self = .init(rawValue: "childLabels")
    
    /// Key: Cache for storing the deep (recursive) labels of all nested children.
    ///
    /// Only applicable to `BasicOperation` and its subclasses.
    internal static let deepLabels: Self = .init(rawValue: "deepLabels")
    
}

#endif
