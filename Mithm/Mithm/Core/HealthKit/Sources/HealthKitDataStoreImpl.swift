//
//  HealthKitCycleDataStore.swift
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
        writeTypes : Set<HKSampleType>,
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
    
    func readSamples(
        type: HKSampleType,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKCategorySample] {
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: []
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let categorySamples = samples as? [HKCategorySample] ?? []
                    continuation.resume(returning: categorySamples)
                }
            }
            
            healthStore.execute(query)
        }
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
            options: []    // 겹치는 샘플 전부 포함
        )
        
        // 삭제된 개수 반환값 무시
        _ = try await healthStore.deleteObjects(of: type, predicate: predicate)
        
        return
    }
}
