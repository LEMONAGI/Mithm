//
//  RecordCurrentMenstrualPeriodUseCaseImpl.swift
//  Mithm
//

import Foundation

struct RecordCurrentMenstrualPeriodUseCaseImpl: RecordCurrentMenstrualPeriodUseCase {

    private let menstrualRecordUseCase: MenstrualRecordUseCase
    private let currentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore
    private let calendar: Calendar
    private let now: () -> Date

    init(
        menstrualRecordUseCase: MenstrualRecordUseCase,
        currentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.currentMenstrualEpisodeStore = currentMenstrualEpisodeStore
        self.calendar = calendar
        self.now = now
    }

    func start(on startDate: Date) async throws {
        let normalizedStartDate = calendar.startOfDay(for: startDate)
        let startRecord = MenstrualRecord(
            type: .menstrualRecord,
            startDate: normalizedStartDate,
            endDate: normalizedStartDate
        )

        try await menstrualRecordUseCase.saveMenstrualRecored(
            startRecord,
            deleteFrom: normalizedStartDate,
            deleteThrough: normalizedStartDate
        )
        currentMenstrualEpisodeStore.saveCurrentEpisode(
            CurrentMenstrualEpisode(
                startDate: normalizedStartDate,
                endDate: nil,
                closedReason: nil
            )
        )
    }

    func end(
        on endDate: Date,
        currentStatus: CurrentMenstrualStatus
    ) async throws -> Bool {
        guard let startDate = currentStatus.activeStartDate
            ?? currentStatus.displayWindow?.startDate else {
            return false
        }

        let normalizedEndDate = max(
            calendar.startOfDay(for: endDate),
            startDate
        )
        let record = MenstrualRecord(
            type: .menstrualRecord,
            startDate: startDate,
            endDate: normalizedEndDate
        )

        try await menstrualRecordUseCase.saveMenstrualRecored(
            record,
            deleteFrom: startDate,
            deleteThrough: now()
        )
        currentMenstrualEpisodeStore.saveCurrentEpisode(
            CurrentMenstrualEpisode(
                startDate: startDate,
                endDate: normalizedEndDate,
                closedReason: .userEnded
            )
        )

        return true
    }
}
