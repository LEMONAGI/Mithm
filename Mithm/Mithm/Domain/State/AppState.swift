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
    @Published var menstrualOverview: MenstrualOverview = MenstrualOverview()
    @Published var menstrualRecordError: Error?
    @Published var userSetting = UserSettingState()

    private let menstrualRecordUseCase: MenstrualRecordUseCase
    private let homePhaseUseCase: HomePhaseUseCase
    private let syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase
    private let userSettingUseCase: UserSettingUseCase

    init(
        menstrualRecordUseCase: MenstrualRecordUseCase,
        homePhaseUseCase: HomePhaseUseCase,
        syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase,
        userSettingUseCase: UserSettingUseCase
    ) {
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.homePhaseUseCase = homePhaseUseCase
        self.syncMenstrualCalendarUseCase = syncMenstrualCalendarUseCase
        self.userSettingUseCase = userSettingUseCase
    }

    // MARK: - Load

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

    // MARK: - Save

    func saveMenstrualRecord(_ record: MenstrualRecord) async throws {
        try await menstrualRecordUseCase.saveMenstrualRecored(record)
        try await refreshMenstrualData()
    }

    func makeCurrentPhaseWindow(activeMenstrualStartDate: Date?) -> PhaseWindow {
        homePhaseUseCase.execute(
            menstrualOverview: menstrualOverview,
            activeMenstrualStartDate: activeMenstrualStartDate,
            today: Date()
        )
    }
}

