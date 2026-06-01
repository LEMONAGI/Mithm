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
    private let foregroundRefreshRetryDelayNanoseconds: UInt64
    private let foregroundRefreshMaxRetryCount: Int
    private var hasPerformedLaunchAutoCloseCheck = false

    // MARK: - Init

    init(
        menstrualRecordUseCase: MenstrualRecordUseCase,
        refreshMenstrualCycleUseCase: RefreshMenstrualCycleUseCase,
        loadUserSettingsUseCase: LoadUserSettingsUseCase,
        userSettingUseCase: UserSettingUseCase,
        syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase,
        foregroundRefreshRetryDelayNanoseconds: UInt64 = 500_000_000,
        foregroundRefreshMaxRetryCount: Int = 2
    ) {
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.refreshMenstrualCycleUseCase = refreshMenstrualCycleUseCase
        self.loadUserSettingsUseCase = loadUserSettingsUseCase
        self.userSettingUseCase = userSettingUseCase
        self.syncMenstrualCalendarUseCase = syncMenstrualCalendarUseCase
        self.foregroundRefreshRetryDelayNanoseconds = foregroundRefreshRetryDelayNanoseconds
        self.foregroundRefreshMaxRetryCount = foregroundRefreshMaxRetryCount
    }

    // MARK: - Public Actions

    /// 앱 최초 실행 시 호출
    func performInitialLoad() async {
        loadUserSettings()
        guard userSetting.hasCompletedOnboarding else {
            return
        }
        await runInitialHealthKitLoad()
    }

    func completeOnboarding() async {
        userSettingUseCase.saveHasCompletedOnboarding(true)
        userSetting.hasCompletedOnboarding = true
        await runInitialHealthKitLoad()
    }

    private func runInitialHealthKitLoad() async {
        do {
            try await menstrualRecordUseCase.requestConfirmedHealthKitAuthorization()
            let shouldRunAutoClose = !hasPerformedLaunchAutoCloseCheck
            hasPerformedLaunchAutoCloseCheck = true
            try await refreshMenstrualData(runAutoClose: shouldRunAutoClose)
        } catch {
            menstrualRecordError = error
        }
    }

    /// scenePhase가 active로 전환될 때 호출
    func refreshOnForeground() async {
        await refreshOnForeground(
            remainingRetryCount: foregroundRefreshMaxRetryCount
        )
    }

    private func refreshOnForeground(remainingRetryCount: Int) async {
        do {
            try await refreshMenstrualData()
        } catch {
            if isTransientProtectedDataError(error) {
                guard remainingRetryCount > 0 else {
                    return
                }
                if foregroundRefreshRetryDelayNanoseconds > 0 {
                    try? await Task.sleep(
                        nanoseconds: foregroundRefreshRetryDelayNanoseconds
                    )
                }
                guard !Task.isCancelled else {
                    return
                }
                await refreshOnForeground(
                    remainingRetryCount: remainingRetryCount - 1
                )
                return
            }
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

    func saveMenstrualUserInput(_ input: MenstrualUserInput) {
        userSettingUseCase.saveMenstrualUserInput(input)
        userSetting.menstrualUserInput = input
        Task {
            try? await refreshMenstrualData()
        }
    }

    func saveUserInputMode(_ mode: UserInputMode) {
        userSettingUseCase.saveUserInputMode(mode)
        userSetting.userInputMode = mode
        Task {
            try? await refreshMenstrualData()
        }
    }

    func saveCalendarExportEnabled(_ enabled: Bool) {
        userSettingUseCase.saveCalendarExportEnabled(enabled)
        userSetting.calendarExportEnabled = enabled

        if !enabled {
            Task {
                try? await syncMenstrualCalendarUseCase.clearExportedEvents()
            }
        } else {
            Task {
                try? await refreshMenstrualData()
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

    private func isTransientProtectedDataError(_ error: Error) -> Bool {
        if let healthKitError = error as? HealthKitError {
            return healthKitError.isTransientProtectedDataError
        }
        if let refreshError = error as? MenstrualCycleRefreshError {
            return isTransientProtectedDataError(refreshError.underlyingError)
        }
        return false
    }

    private func apply(_ snapshot: MenstrualCycleSnapshot) {
        menstrualOverview = snapshot.overview
        currentMenstrualStatus = snapshot.currentStatus
        if snapshot.didAutoClose {
            didAutoCloseMenstruation = true
        }
    }
}
