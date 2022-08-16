//
//  OperationQueueStatus Testing Extensions.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if shouldTestCurrentPlatform

import Foundation
import OTOperations

extension OperationQueueStatus {
    // MARK: Helper methods for unit tests
    
    var inProgressFractionCompleted: Double? {
        guard case .inProgress(
            fractionCompleted: let frac,
            label: _,
            description: _
        ) = self
        else { return nil }
        
        return frac
    }
    
    var inProgressLabel: String? {
        guard case .inProgress(
            fractionCompleted: _,
            label: let label,
            description: _
        ) = self
        else { return nil }
        
        return label
    }
    
    var inProgressDescription: String? {
        guard case .inProgress(
            fractionCompleted: _,
            label: _,
            description: let desc
        ) = self
        else { return nil }
        
        return desc
    }
}

extension OperationQueueStatus {
    enum Testable {
        /// Returns values as-is, except `inProgress` which returns only the `fractionCompleted` associated value.
        enum FractionCompleted: Equatable, Hashable {
            case idle
            case paused
            case inProgress(fractionCompleted: Double)
        }
        
        /// Returns values as-is, except `inProgress` which returns only the `description` associated value.
        enum Description: Equatable, Hashable {
            case idle
            case paused
            case inProgress(description: String)
        }
    }
}

extension Collection where Element == OperationQueueStatus {
    func convertedToTestableFractionCompleted()
    -> [OperationQueueStatus.Testable.FractionCompleted] {
        map {
            switch $0 {
            case .idle:
                return .idle
            case let .inProgress(fractionCompleted, _, _):
                return .inProgress(fractionCompleted: fractionCompleted)
            case .paused:
                return .paused
            }
        }
    }
    
    func convertedToTestableDescription() -> [OperationQueueStatus.Testable.Description] {
        map {
            switch $0 {
            case .idle:
                return .idle
            case let .inProgress(_, _, description):
                return .inProgress(description: description)
            case .paused:
                return .paused
            }
        }
    }
}

#endif
