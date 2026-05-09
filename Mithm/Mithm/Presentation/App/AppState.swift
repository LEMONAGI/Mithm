//
//  AppState.swift
//  Mithm
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
    @Published var didAutoCloseMenstruation = false

    // MARK: - Dependencies

    private let menstrualRecordUseCase: MenstrualRecordUseCase
    private let refreshMenstrualCycleUseCase: RefreshMenstrualCycleUseCase
    private let loadUserSettingsUseCase: LoadUserSettingsUseCase
    private let userSettingUseCase: UserSettingUseCase
    private let syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase
    private var hasPerformedLaunchAutoCloseCheck = false

    // MARK: - Init

    init(
        menstrualRecordUseCase: MenstrualRecordUseCase,
        refreshMenstrualCycleUseCase: RefreshMenstrualCycleUseCase,
        loadUserSettingsUseCase: LoadUserSettingsUseCase,
        userSettingUseCase: UserSettingUseCase,
        syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase
    ) {
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.refreshMenstrualCycleUseCase = refreshMenstrualCycleUseCase
        self.loadUserSettingsUseCase = loadUserSettingsUseCase
        self.userSettingUseCase = userSettingUseCase
        self.syncMenstrualCalendarUseCase = syncMenstrualCalendarUseCase
    }

    // MARK: - Public Actions

    /// 앱 최초 실행 시 호출
    func performInitialLoad() async {
        loadUserSettings()
        do {
            try await menstrualRecordUseCase.requestHealthKitAuthorization()
            let shouldRunAutoClose = !hasPerformedLaunchAutoCloseCheck
            hasPerformedLaunchAutoCloseCheck = true
            try await refreshMenstrualData(runAutoClose: shouldRunAutoClose)
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
        try await refreshMenstrualData(runAutoClose: false)
    }

    func loadUserSettings() {
        userSetting = loadUserSettingsUseCase.execute()
    }

    func saveCalendarExportEnabled(_ enabled: Bool) {
        userSettingUseCase.saveCalendarExportEnabled(enabled)
        userSetting.calendarExportEnabled = enabled

        if !enabled {
            Task {
                try? await syncMenstrualCalendarUseCase.removeCalendar()
            }
        }
    }

    private func refreshMenstrualData(runAutoClose: Bool) async throws {
        do {
            let snapshot = try await refreshMenstrualCycleUseCase.execute(
                userSetting: userSetting,
                runAutoClose: runAutoClose
            )
            apply(snapshot)
        } catch let error as MenstrualCycleRefreshError {
            apply(error.snapshot)
            throw error.underlyingError
        }
    }

    private func apply(_ snapshot: MenstrualCycleSnapshot) {
        menstrualOverview = snapshot.overview
        currentMenstrualStatus = snapshot.currentStatus
        if snapshot.didAutoClose {
            didAutoCloseMenstruation = true
        }
    }
}
