//
//  EventStoreError.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import Foundation

enum EventKitError: Error {
    case accessFail
    case noSuitableSource
    case eventCreationFail(Error)
}

extension EventKitError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .accessFail:
            return NSLocalizedString("The app doesn't have permission to Calendar in Settings.",
                                     comment: "Access denied")
        case .noSuitableSource:
            return NSLocalizedString("The app doesn't have any Calendar in Settings.",
                              comment: "No suitable source")
        case .eventCreationFail(let error):
            return NSLocalizedString("The app failed to create an event. By \(error)",
                                     comment: "Failed to create an event")
        }
    }
}
