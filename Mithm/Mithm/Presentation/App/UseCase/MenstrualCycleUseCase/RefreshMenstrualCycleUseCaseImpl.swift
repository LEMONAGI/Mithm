//
//  RefreshMenstrualCycleUseCaseImpl.swift
//  Mithm
//

import Foundation

struct RefreshMenstrualCycleUseCaseImpl: RefreshMenstrualCycleUseCase {

    private let menstrualRecordUseCase: MenstrualRecordUseCase
    private let syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase
    private let currentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore
    private let currentMenstrualStatusResolver: CurrentMenstrualStatusResolver
    private let calendar: Calendar

    init(
        menstrualRecordUseCase: MenstrualRecordUseCase,
        syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase,
        currentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore,
        currentMenstrualStatusResolver: CurrentMenstrualStatusResolver,
        calendar: Calendar = .current
    ) {
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.syncMenstrualCalendarUseCase = syncMenstrualCalendarUseCase
        self.currentMenstrualEpisodeStore = currentMenstrualEpisodeStore
        self.currentMenstrualStatusResolver = currentMenstrualStatusResolver
        self.calendar = calendar
    }

    func execute(
        userSetting: UserSettingState,
        runAutoClose: Bool,
        referenceDate: Date = Date()
    ) async throws -> MenstrualCycleSnapshot {
        var overview = try await fetchMenstrualOverview(
            userSetting: userSetting
        )
        clearStaleCurrentEpisodeIfNeeded(actualRecords: overview.actualRecords)
        var status = resolveCurrentMenstrualStatus(
            from: overview,
            referenceDate: referenceDate
        )

        if status.isActive, let activeStartDate = status.activeStartDate {
            overview = try await fetchMenstrualOverview(
                userSetting: userSetting,
                activeMenstrualStartDate: activeStartDate
            )
            status = resolveCurrentMenstrualStatus(
                from: overview,
                referenceDate: referenceDate
            )
        }

        var didAutoClose = false
        if runAutoClose,
           status.isActive,
           status.shouldAutoClose,
           let latestStartDate = status.latestStartDate,
           let expectedEndDate = status.expectedEndDate {
            try await closeCurrentEpisode(
                startDate: latestStartDate,
                endDate: expectedEndDate,
                deleteThrough: referenceDate
            )
            didAutoClose = true
            overview = try await fetchMenstrualOverview(
                userSetting: userSetting
            )
            status = resolveCurrentMenstrualStatus(
                from: overview,
                referenceDate: referenceDate
            )
        }

        let snapshot = MenstrualCycleSnapshot(
            overview: overview,
            currentStatus: status,
            didAutoClose: didAutoClose
        )

        do {
            try await syncMenstrualCalendarUseCase.execute(
                records: overview.allRecords,
                isEnabled: userSetting.calendarExportEnabled
            )
        } catch {
            throw MenstrualCycleRefreshError(
                snapshot: snapshot,
                underlyingError: error
            )
        }

        return snapshot
    }

    private func fetchMenstrualOverview(
        userSetting: UserSettingState,
        activeMenstrualStartDate: Date? = nil
    ) async throws -> MenstrualOverview {
        try await menstrualRecordUseCase.fetchMenstrualOverview(
            activeMenstrualStartDate: activeMenstrualStartDate,
            userInput: userSetting.menstrualUserInput,
            userInputMode: userSetting.userInputMode
        )
    }

    private func resolveCurrentMenstrualStatus(
        from overview: MenstrualOverview,
        referenceDate: Date
    ) -> CurrentMenstrualStatus {
        currentMenstrualStatusResolver.resolve(
            actualRecords: overview.actualRecords,
            currentEpisode: currentMenstrualEpisodeStore.loadCurrentEpisode(),
            predictedPeriodLength: overview.prediction?.predictedPeriodLength,
            today: referenceDate,
            calendar: calendar
        )
    }

    private func clearStaleCurrentEpisodeIfNeeded(
        actualRecords: [MenstrualRecord]
    ) {
        guard let currentEpisode = currentMenstrualEpisodeStore.loadCurrentEpisode() else {
            return
        }

        let episodeStartDate = calendar.startOfDay(for: currentEpisode.startDate)
        guard let matchingHealthRecord = actualRecords.first(where: {
            $0.type == .menstrualRecord
                && calendar.isDate($0.startDate, inSameDayAs: episodeStartDate)
        }) else {
            currentMenstrualEpisodeStore.clearCurrentEpisode()
            return
        }

        if currentEpisode.isClosed
            && !isSameDay(currentEpisode.endDate, matchingHealthRecord.endDate) {
            currentMenstrualEpisodeStore.clearCurrentEpisode()
        }
    }

    private func isSameDay(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return calendar.isDate(lhs, inSameDayAs: rhs)
        case (nil, nil):
            return true
        default:
            return false
        }
    }

    private func closeCurrentEpisode(
        startDate: Date,
        endDate: Date,
        deleteThrough: Date
    ) async throws {
        let closedRecord = MenstrualRecord(
            type: .menstrualRecord,
            startDate: startDate,
            endDate: endDate
        )
        try await menstrualRecordUseCase.saveMenstrualRecored(
            closedRecord,
            deleteFrom: startDate,
            deleteThrough: deleteThrough
        )
        currentMenstrualEpisodeStore.saveCurrentEpisode(
            CurrentMenstrualEpisode(
                startDate: startDate,
                endDate: endDate,
                closedReason: .autoClosed
            )
        )
    }
}
