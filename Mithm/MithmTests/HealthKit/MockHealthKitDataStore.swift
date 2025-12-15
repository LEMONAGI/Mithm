//
//  MockHealthKitDataStore.swift
//  Mithm
//
//  Created by YunhakLee on 12/15/25.
//


import Foundation
import HealthKit
@testable import Mithm

final class MockHealthKitDataStore: HealthKitDataStore {

    // MARK: - Configurable outputs

    var isAvailable: Bool = true
    var writeAuthStatus: HKAuthorizationStatus = .sharingAuthorized

    var readSamplesResult: [HKCategorySample] = []

    // MARK: - Call recording

    private(set) var requestedAuthWriteTypes: Set<HKSampleType> = []
    private(set) var requestedAuthReadTypes: Set<HKObjectType> = []
    private(set) var didRequestAuthorization = false

    private(set) var savedObjects: [HKObject] = []

    private(set) var deleteCalls: [(type: HKObjectType, from: Date, to: Date)] = []

    /// 순서 검증용 (delete -> save 등)
    private(set) var callOrder: [String] = []

    // MARK: - HealthKitDataStore

    func isHealthDataAvailable() -> Bool {
        isAvailable
    }

    func requestAuthorization(
        writeTypes: Set<HKSampleType>,
        readTypes: Set<HKObjectType>
    ) async throws {
        didRequestAuthorization = true
        requestedAuthWriteTypes = writeTypes
        requestedAuthReadTypes = readTypes
        callOrder.append("requestAuthorization")
    }

    func checkWriteAuthorization(for type: HKObjectType) -> HKAuthorizationStatus {
        writeAuthStatus
    }

    func saveSamples(samples: [HKObject]) async throws {
        savedObjects.append(contentsOf: samples)
        callOrder.append("saveSamples")
    }

    func readSamples(
        type: HKSampleType,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKCategorySample] {
        callOrder.append("readSamples")
        return readSamplesResult
    }

    func deleteSamples(
        type: HKObjectType,
        from startDate: Date,
        to endDate: Date
    ) async throws {
        deleteCalls.append((type: type, from: startDate, to: endDate))
        callOrder.append("deleteSamples")
    }
}