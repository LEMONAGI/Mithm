//
//  AppState.swift
//  Mithm
//
//  Created by YunhakLee on 12/17/25.
//

import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {

    // MARK: - Published State

    @Published var menstrualOverview: MenstrualOverview = MenstrualOverview()
    @Published var menstrualRecordError: Error?
    @Published var userSetting = UserSettingState()
    @Published var currentMenstrualStatus: CurrentMenstrualStatus = .inactive()

    // MARK: - Dependencies

    private let menstrualRecordUseCase: MenstrualRecordUseCase
    private let syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase
    private let userSettingUseCase: UserSettingUseCase
    private let currentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore
    private let currentMenstrualStatusResolver: CurrentMenstrualStatusResolver

    // MARK: - Init

    init(
        menstrualRecordUseCase: MenstrualRecordUseCase,
        syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase,
        userSettingUseCase: UserSettingUseCase,
        currentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore,
        currentMenstrualStatusResolver: CurrentMenstrualStatusResolver
    ) {
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.syncMenstrualCalendarUseCase = syncMenstrualCalendarUseCase
        self.userSettingUseCase = userSettingUseCase
        self.currentMenstrualEpisodeStore = currentMenstrualEpisodeStore
        self.currentMenstrualStatusResolver = currentMenstrualStatusResolver
    }

    // MARK: - Public Actions

    /// 앱 최초 실행 시 호출
    func performInitialLoad() async {
        loadUserSettings()
        do {
            try await menstrualRecordUseCase.requestHealthKitAuthorization()
            try await refreshMenstrualData()
        } catch {
            menstrualRecordError = error
        }
    }

    /// scenePhase가 active로 전환될 때 호출
    func refreshOnForeground() async {
        do {
            try await refreshMenstrualData()
        } catch {
            menstrualRecordError = error
        }
    }

    /// 월경 기록 변경 후 데이터 갱신
    func refreshMenstrualData() async throws {
        var overview = try await menstrualRecordUseCase.fetchMenstrualOverview()
        var status = resolveCurrentMenstrualStatus(from: overview)

        if status.isActive, let activeStartDate = status.activeStartDate {
            overview = try await menstrualRecordUseCase.fetchMenstrualOverview(
                activeMenstrualStartDate: activeStartDate
            )
            status = resolveCurrentMenstrualStatus(from: overview)
        }

        if status.shouldAutoClose,
           let latestStartDate = status.latestStartDate,
           let expectedEndDate = status.expectedEndDate {
            let closedRecord = MenstrualRecord(
                type: .menstrualRecord,
                startDate: latestStartDate,
                endDate: expectedEndDate
            )
            try await menstrualRecordUseCase.saveMenstrualRecored(
                closedRecord,
                deleteFrom: latestStartDate,
                deleteThrough: Date()
            )
            currentMenstrualEpisodeStore.saveCurrentEpisode(
                CurrentMenstrualEpisode(
                    startDate: latestStartDate,
                    endDate: expectedEndDate,
                    closedReason: .autoClosed
                )
            )
            overview = try await menstrualRecordUseCase.fetchMenstrualOverview()
            status = resolveCurrentMenstrualStatus(from: overview)
        }

        menstrualOverview = overview
        currentMenstrualStatus = status

        try await syncMenstrualCalendarUseCase.execute(
            records: overview.allRecords,
            isEnabled: userSetting.calendarExportEnabled
        )
    }

    func loadUserSettings() {
        userSetting = UserSettingState(
            menstrualUserInput: userSettingUseCase.loadMenstrualUserInput(),
            calendarExportEnabled: userSettingUseCase.loadCalendarExportEnabled(),
            userInputMode: userSettingUseCase.loadUserInputMode()
        )
    }

    private func resolveCurrentMenstrualStatus(
        from overview: MenstrualOverview
    ) -> CurrentMenstrualStatus {
        currentMenstrualStatusResolver.resolve(
            actualRecords: overview.actualRecords,
            currentEpisode: currentMenstrualEpisodeStore.loadCurrentEpisode(),
            predictedPeriodLength: overview.prediction?.predictedPeriodLength
        )
    }
}
