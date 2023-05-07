//
//  SPSDomainError.swift
//  
//
//  Created by Martin Lukacs on 01/05/2023.
//

import Foundation

public enum SPSDomainError: Int {
    case noFileFound = 0
    case serialization = 1
    case deserialization = 2
    case invalidFileName = 3
    case couldNotAccessTemporaryDirectory = 4
    case couldNotAccessUserDomainMask = 5
    case couldNotAccessSharedContainer = 6

    var errorDomain: String {
        "DiskErrorDomain"
    }

    /// Create custom error that FileManager can't account for
    func createEnhancedError(description: String?,
                             failureReason: String?,
                             recoverySuggestion: String?) -> Error {
        let errorInfo: [String: Any] = [NSLocalizedDescriptionKey : description ?? "",
                             NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion ?? "",
                                  NSLocalizedFailureReasonErrorKey: failureReason ?? ""]
        return NSError(domain: errorDomain, code: self.rawValue, userInfo: errorInfo) as Error
    }
}
