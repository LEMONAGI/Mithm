//
//  MenstrualRecordUseCaseDemoViewModel.swift
//  Mithm
//
//  Created by OpenAI on 3/11/26.
//

import Foundation
import Combine

@MainActor
final class MenstrualRecordUseCaseDemoViewModel: ObservableObject {

    @Published var records: [MenstrualRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastLoadedAt: Date?
    @Published var lastExportedToCalendarAt: Date?

    private let healthKitRepository: HealthKitRepository
    private let eventKitRepository: EventKitRepository
    private let useCase: any MenstrualRecordUseCase

    init(
        healthKitRepository: HealthKitRepository? = nil,
        eventKitRepository: EventKitRepository? = nil,
        useCase: (any MenstrualRecordUseCase)? = nil
    ) {
        let resolvedRepository = healthKitRepository ?? HealthKitRepositoryImpl(
            dataStore: HealthKitDataStoreImpl()
        )
        let resolvedEventKitRepository = eventKitRepository ?? EventKitRepositoryImpl(
            dataStore: EventKitDataStoreImpl()
        )

        self.healthKitRepository = resolvedRepository
        self.eventKitRepository = resolvedEventKitRepository
        self.useCase = useCase ?? MenstrualRecordUseCaseImpl(
            healthKitRepository: resolvedRepository
        )
    }

    var groupedCounts: [(title: String, count: Int)] {
        let grouped = Dictionary(grouping: records, by: \.type)

        return MenstrualRecordType.allCases.compactMap { type in
            guard let items = grouped[type], !items.isEmpty else { return nil }
            return (type.title, items.count)
        }
    }

    func requestAuthorizationAndLoad() {
        Task {
            await runLoadingTask {
                try await self.healthKitRepository.requestAuthorization(
                    writeTypes: [.menstrualCycle],
                    readTypes: [.menstrualCycle]
                )
                try await self.loadRecords()
            }
        }
    }

    func reload() {
        Task {
            await runLoadingTask {
                try await self.loadRecords()
            }
        }
    }

    func saveRecord(startDate: Date, endDate: Date) {
        Task {
            await runLoadingTask {
                let normalizedStart = Calendar.current.startOfDay(for: startDate)
                let normalizedEnd = Calendar.current.startOfDay(for: endDate)
                let record = MenstrualRecord(
                    type: .menstrualRecord,
                    startDate: min(normalizedStart, normalizedEnd),
                    endDate: max(normalizedStart, normalizedEnd)
                )

                try await self.useCase.saveMenstrualRecored(record, deleteFrom: nil, deleteThrough: nil)
                try await self.loadRecords()
            }
        }
    }

    private func loadRecords() async throws {
        let overview = try await useCase.fetchMenstrualOverview()

        records = overview.allRecords
        lastLoadedAt = Date()
        try await exportFetchedRecordsToCalendar(overview.allRecords)
        errorMessage = nil
    }

    private func exportFetchedRecordsToCalendar(_ records: [MenstrualRecord]) async throws {
        guard !records.isEmpty else {
            lastExportedToCalendarAt = nil
            return
        }

        _ = try await eventKitRepository.verifyCalendarAccess()
        try await eventKitRepository.syncRecordsToCalendar(records)
        lastExportedToCalendarAt = Date()
    }

    private func runLoadingTask(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension MenstrualRecordType {
    static var allCases: [MenstrualRecordType] {
        [
            .menstrualRecord,
            .menstrualPrediction,
            .ovulationEstimated,
            .ovulationFertileWindowEstimated,
            .ovulationPrediction,
            .ovulationFertileWindowPrediction
        ]
    }
}
