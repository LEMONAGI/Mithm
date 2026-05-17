//
//  MenstrualRecordEditingUseCaseImpl.swift
//  Mithm
//

import Foundation

struct MenstrualRecordEditingUseCaseImpl: MenstrualRecordEditingUseCase {

    private let menstrualRecordUseCase: MenstrualRecordUseCase
    private let currentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore
    private let calendar: Calendar

    init(
        menstrualRecordUseCase: MenstrualRecordUseCase,
        currentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore,
        calendar: Calendar = .current
    ) {
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.currentMenstrualEpisodeStore = currentMenstrualEpisodeStore
        self.calendar = calendar
    }

    func update(
        originalRecord: MenstrualRecord,
        startDate: Date,
        endDate: Date
    ) async throws {
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let normalizedEndDate = max(
            calendar.startOfDay(for: endDate),
            normalizedStartDate
        )
        let updatedRecord = MenstrualRecord(
            type: .menstrualRecord,
            startDate: normalizedStartDate,
            endDate: normalizedEndDate
        )

        try await menstrualRecordUseCase.saveMenstrualRecored(
            updatedRecord,
            deleteFrom: calendar.startOfDay(for: originalRecord.startDate),
            deleteThrough: deleteEndDate(for: originalRecord)
        )
        updateCurrentEpisodeIfNeeded(
            originalRecord: originalRecord,
            updatedStartDate: normalizedStartDate,
            updatedEndDate: normalizedEndDate
        )
    }

    func delete(_ record: MenstrualRecord) async throws {
        try await menstrualRecordUseCase.deleteMenstrualRecord(
            from: calendar.startOfDay(for: record.startDate),
            to: deleteEndDate(for: record)
        )
        clearCurrentEpisodeIfNeeded(for: record)
    }

    private func deleteEndDate(for record: MenstrualRecord) -> Date {
        calendar.startOfDay(for: record.endDate ?? record.startDate)
    }

    private func updateCurrentEpisodeIfNeeded(
        originalRecord: MenstrualRecord,
        updatedStartDate: Date,
        updatedEndDate: Date
    ) {
        guard let currentEpisode = currentMenstrualEpisodeStore.loadCurrentEpisode(),
              calendar.isDate(currentEpisode.startDate, inSameDayAs: originalRecord.startDate)
        else { return }

        currentMenstrualEpisodeStore.saveCurrentEpisode(
            CurrentMenstrualEpisode(
                startDate: updatedStartDate,
                endDate: updatedEndDate,
                closedReason: currentEpisode.closedReason ?? .userEnded
            )
        )
    }

    private func clearCurrentEpisodeIfNeeded(for record: MenstrualRecord) {
        guard let currentEpisode = currentMenstrualEpisodeStore.loadCurrentEpisode(),
              calendar.isDate(currentEpisode.startDate, inSameDayAs: record.startDate)
        else { return }

        currentMenstrualEpisodeStore.clearCurrentEpisode()
    }
}
