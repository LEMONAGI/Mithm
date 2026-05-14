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
            readTypes: [.menstrualCycle]
        )
    }

    func requestConfirmedHealthKitAuthorization() async throws {
        try await requestHealthKitAuthorization()
        try await healthKitRepository.checkWriteAuthorization(for: .menstrualCycle)
    }

    func fetchMenstrualOverview(
        activeMenstrualStartDate: Date? = nil,
        userInput: MenstrualUserInput? = nil,
        userInputMode: UserInputMode? = nil
    ) async throws -> MenstrualOverview {
        let now = Date()
        let from = calendar.date(byAdding: .year, value: -100, to: now)!
        let to = now

        let actualRecords = try await healthKitRepository.readMenstrualCycleRecords(
            from: from,
            to: to
        )

        let predictionSourceRecords = makePredictionSourceRecords(
            from: actualRecords,
            activeMenstrualStartDate: activeMenstrualStartDate
        )
        let predictionEngine = makePredictionEngine(userInputMode: userInputMode)
        let predictionResult = predictionEngine.predict(
            from: predictionSourceRecords,
            userInput: userInput,
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

    func deleteMenstrualRecord(from startDate: Date, to endDate: Date) async throws {
        try await healthKitRepository.checkWriteAuthorization(for: .menstrualCycle)
        try await healthKitRepository.deleteMenstrualCycleRecords(
            from: startDate,
            to: endDate
        )
    }

    private func makePredictionSourceRecords(
        from actualRecords: [MenstrualRecord],
        activeMenstrualStartDate: Date?
    ) -> [MenstrualRecord] {
        guard let activeMenstrualStartDate else {
            return actualRecords
        }

        let activeStartDate = calendar.startOfDay(for: activeMenstrualStartDate)
        let recordsExcludingActiveEpisode = actualRecords.filter {
            !calendar.isDate($0.startDate, inSameDayAs: activeStartDate)
        }
        let openRecord = MenstrualRecord(
            type: .menstrualRecord,
            startDate: activeStartDate,
            endDate: nil
        )

        return recordsExcludingActiveEpisode + [openRecord]
    }

    private func makePredictionEngine(
        userInputMode: UserInputMode?
    ) -> MenstrualPredictionEngine {
        guard let userInputMode else {
            return predictionEngine
        }

        return MenstrualPredictionEngine(
            config: predictionEngine.config,
            userInputMode: userInputMode
        )
    }
}
