//
//  HealthKitRepositoryImpl.swift
//  Mithm
//
//  Created by YunhakLee on 11/20/25.
//

import Foundation
import HealthKit

final class HealthKitRepositoryImpl: HealthKitRepository {
    
    private let dataStore: HealthKitDataStore
    
    init(dataStore: HealthKitDataStore) {
        self.dataStore = dataStore
    }
    
    // MARK: - Authorization
    
    func checkWriteAuthorization(
        for type: HealthDataType
    ) async throws {
        guard dataStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }
        
        let hkObjectType = HealthKitMapper.hkObjectType(from: type)
        let status = dataStore.checkWriteAuthorization(for: hkObjectType)
        
        switch status {
        case .sharingAuthorized:
            return
        case .notDetermined:
            throw HealthKitError.authorizationNotDetermined
        case .sharingDenied:
            throw HealthKitError.authorizationDenied
        @unknown default:
            throw HealthKitError.authorizationDenied
        }
    }
    
    func requestAuthorization(
        writeTypes: Set<HealthDataType>,
        readTypes: Set<HealthDataType>
    ) async throws {
        guard dataStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }
        
        let writeTypes: Set<HKSampleType> = try HealthKitMapper.hkSampleTypes(from: writeTypes)
        let readTypes: Set<HKObjectType> = HealthKitMapper.hkObjectTypes(from: readTypes)
        
        do {
            try await dataStore.requestAuthorization(
                writeTypes: writeTypes,
                readTypes: readTypes
            )
        } catch {
            throw HealthKitError.authorizationRequestFailed(error)
        }
    }
    
    // MARK: - MenstrualCycleRecord
    
    func readMenstrualCycleRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [MenstrualRecord] {
        let samples: [HKCategorySample] = try await dataStore.readSamples(
            type: HealthKitMapper.hkSampleType(from: .menstrualCycle),
            from: startDate,
            to: endDate
        )
        
        return HealthKitMapper.menstrualCycleRecords(from: samples)
    }
    
    func updateMenstrualCycleRecord(
        _ record: MenstrualRecord
    ) async throws {
        let objectType = HealthKitMapper.hkObjectType(from: .menstrualCycle)
        try await dataStore.deleteSamples(type: objectType, from: record.startDate, to: record.endDate ?? record.startDate)
        
        let samples = try HealthKitMapper.hkMenstrualCycleSamples(from: record)
        try await dataStore.saveSamples(samples: samples)
    }
}
