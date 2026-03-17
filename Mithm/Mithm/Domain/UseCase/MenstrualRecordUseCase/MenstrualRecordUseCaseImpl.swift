//
//  MenstrualRecordUseCaseImpl.swift
//  Mithm
//
//  Created by YunhakLee on 12/17/25.
//

import Foundation

struct MenstrualRecordUseCaseImpl: MenstrualRecordUseCase {
    
    private let calendar: Calendar
    private let healthKitRepository: HealthKitRepository
    private let predictionEngine: MenstrualPredictionEngine
    private let ovulationRecordGenerator: OvulationRecordGenerator
    
    init(
        healthKitRepository: HealthKitRepository,
        predictionEngine: MenstrualPredictionEngine = MenstrualPredictionEngine(),
        ovulationRecordGenerator: OvulationRecordGenerator = OvulationRecordGenerator(),
        calendar: Calendar = .current
    ) {
        self.healthKitRepository = healthKitRepository
        self.predictionEngine = predictionEngine
        self.ovulationRecordGenerator = ovulationRecordGenerator
        self.calendar = calendar
    }
    
    func requestHealthKitAuthorization() async throws {
        try await healthKitRepository.requestAuthorization(
            writeTypes: [.menstrualCycle],
            readTypes: [.menstrualCycle, .wristTemperature]
        )
    }

    func fetchMenstrualOverview() async throws -> MenstrualOverview {
        let now = Date()
        let from = calendar.date(byAdding: .year, value: -100, to: now)!
        let to = now

        let actualRecords = try await healthKitRepository.readMenstrualCycleRecords(
            from: from,
            to: to
        )
        
        let predictionResult = predictionEngine.predict(
            from: actualRecords,
            calendar: calendar
        )
        let predictedMenstrualRecords = predictionResult.menstrualPredictions

        let normalizedActualRecords = actualRecords.filter { $0.endDate != nil }
        let baseRecords = normalizedActualRecords + predictedMenstrualRecords
        let ovulationRecords = ovulationRecordGenerator.generate(
            from: baseRecords,
            calendar: calendar
        )

        let allRecords = (baseRecords + ovulationRecords)
            .sorted { lhs, rhs in
                if lhs.startDate == rhs.startDate {
                    return (lhs.endDate ?? lhs.startDate) < (rhs.endDate ?? rhs.startDate)
                }
                return lhs.startDate < rhs.startDate
            }
        
        return MenstrualOverview(
            actualRecords: actualRecords,
            allRecords: allRecords,
            prediction: predictionResult)
    }
    
    func saveMenstrualRecored(_ record: MenstrualRecord, deleteFrom: Date? = nil, deleteThrough: Date? = nil) async throws {
        try await healthKitRepository.checkWriteAuthorization(for: .menstrualCycle)
        try await healthKitRepository.updateMenstrualCycleRecord(record, deleteFrom: deleteFrom, deleteThrough: deleteThrough)
    }
}
