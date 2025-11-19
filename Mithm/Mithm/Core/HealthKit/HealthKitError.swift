//
//  HealthKitError.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//


enum HealthKitError: Error {
    case notAvailableOnDevice
    case missingType
    case authorizationDenied
    case noSharingPermission
}
