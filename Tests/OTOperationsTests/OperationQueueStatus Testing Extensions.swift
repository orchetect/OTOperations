//
//  OperationQueueStatus Testing Extensions.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if shouldTestCurrentPlatform

import Foundation
import OTOperations

extension OperationQueueStatus {
    
    // MARK: Helper methods for unit tests
    
    var inProgressFractionCompleted: Double? {
        
        guard case .inProgress(fractionCompleted: let frac,
                               label: _,
                               description: _) = self
        else { return nil }
        
        return frac
        
    }
    
    var inProgressLabel: String? {
        
        guard case .inProgress(fractionCompleted: _,
                               label: let label,
                               description: _) = self
        else { return nil }
        
        return label
        
    }
    
    var inProgressDescription: String? {
        
        guard case .inProgress(fractionCompleted: _,
                               label: _,
                               description: let desc) = self
        else { return nil }
        
        return desc
        
    }
    
}

#endif
