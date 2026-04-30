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

    // MARK: - Dependencies

    private let menstrualRecordUseCase: MenstrualRecordUseCase
    private let syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase
    private let userSettingUseCase: UserSettingUseCase

    // MARK: - Init

    init(
        menstrualRecordUseCase: MenstrualRecordUseCase,
        syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase,
        userSettingUseCase: UserSettingUseCase
    ) {
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.syncMenstrualCalendarUseCase = syncMenstrualCalendarUseCase
        self.userSettingUseCase = userSettingUseCase
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
        let overview = try await menstrualRecordUseCase.fetchMenstrualOverview()
        menstrualOverview = overview

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
}

