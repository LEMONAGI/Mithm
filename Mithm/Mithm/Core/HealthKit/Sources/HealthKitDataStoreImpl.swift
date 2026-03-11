//
//  HealthKitDataStoreImpl.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation
import HealthKit

final class HealthKitDataStoreImpl: HealthKitDataStore {
    
    private let healthStore = HKHealthStore()
    private let calendar = Calendar.current
    
    
    // MARK: - Authorization
    
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization(
        writeTypes: Set<HKSampleType>,
        readTypes: Set<HKObjectType>
    ) async throws {
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
    }
    
    func checkWriteAuthorization(
        for type: HKObjectType
    ) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type)
    }
    
    
    // MARK: - CRUD
    
    func saveSamples(
        samples: [HKObject]
    ) async throws {
        try await healthStore.save(samples)
    }
    
    func readCategorySamples(
        type: HKCategoryType,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKCategorySample] {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate
        )
        let sortDescriptor = SortDescriptor(\HKCategorySample.startDate, order: .forward)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: type, predicate: predicate)],
            sortDescriptors: [sortDescriptor]
        )

        return try await descriptor.result(for: healthStore)
    }

    func readQuantitySamples(
        type: HKQuantityType,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate
        )
        let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .forward)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: predicate)],
            sortDescriptors: [sortDescriptor]
        )

        return try await descriptor.result(for: healthStore)
    }
    
    func deleteSamples(
        type: HKObjectType,
        from startDate: Date,
        to endDate: Date
    ) async throws {
        let startDay = calendar.startOfDay(for: startDate)
        let endDay   = calendar.startOfDay(for: endDate)
        
        guard startDay <= endDay else { return }
        
        var comps = calendar.dateComponents([.year, .month, .day], from: endDate)
        comps.hour = 23
        comps.minute = 59
        comps.second = 59
        guard let endOfLastDay = calendar.date(from: comps) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDay,
            end: endOfLastDay,
            options: []
        )
        
        _ = try await healthStore.deleteObjects(of: type, predicate: predicate)
    }
}
