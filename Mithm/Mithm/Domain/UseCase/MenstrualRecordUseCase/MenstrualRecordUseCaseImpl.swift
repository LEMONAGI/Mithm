//
//  MenstrualRecordUseCaseImpl.swift
//  Mithm
//
//  Created by YunhakLee on 12/17/25.
//

import Foundation

struct MenstrualRecordUseCaseImpl: MenstrualRecordUseCase {
    
    private let calendar = Calendar.current
    private let healthKitRepository: HealthKitRepository
    private let menstrualPredictionEngine = MenstrualPredictionEngine()
    
    init(healthKitRepository: HealthKitRepository) {
        self.healthKitRepository = healthKitRepository
    }
    
    func fetchMenstrualRecords() async throws -> [MenstrualRecord] {
        let now = Date()
        let from = calendar.date(byAdding: .year, value: -100, to: now)!
        let to = now

        let records = try await healthKitRepository.readMenstrualCycleRecords(
            from: from,
            to: to
        )
        
        return menstrualPredictionEngine.makePredictions(from: records)
    }
    
    func saveMenstrualRecored(_ record: MenstrualRecord) async throws {
        try await healthKitRepository.checkWriteAuthorization(for: .menstrualCycle)
        try await healthKitRepository.updateMenstrualCycleRecord(record)
    }
}
