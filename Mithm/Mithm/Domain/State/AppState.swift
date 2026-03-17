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

    private let calendar: Calendar
    private let menstrualRecordUseCase: MenstrualRecordUseCase
    private let homePhaseUseCase: HomePhaseUseCase
    private let openPeriodAutoCloser: OpenPeriodAutoCloser
    private let syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase
    private let userSettingUseCase: UserSettingUseCase

    init(
        calendar: Calendar = .current,
        menstrualRecordUseCase: MenstrualRecordUseCase,
        homePhaseUseCase: HomePhaseUseCase,
        openPeriodAutoCloser: OpenPeriodAutoCloser,
        syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase,
        userSettingUseCase: UserSettingUseCase
    ) {
        self.calendar = calendar
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.homePhaseUseCase = homePhaseUseCase
        self.openPeriodAutoCloser = openPeriodAutoCloser
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

    func requestHealthKitAuthorization() async throws {
        try await menstrualRecordUseCase.requestHealthKitAuthorization()
    }

    // MARK: - Save

    func saveMenstrualRecord(_ record: MenstrualRecord, deleteFrom: Date? = nil, deleteThrough: Date? = nil) async throws {
        try await menstrualRecordUseCase.saveMenstrualRecored(record, deleteFrom: deleteFrom, deleteThrough: deleteThrough)
        try await refreshMenstrualData()
    }

    func makeCurrentPhaseWindow(activeMenstrualStartDate: Date?) -> PhaseWindow {
        homePhaseUseCase.execute(
            menstrualOverview: menstrualOverview,
            activeMenstrualStartDate: activeMenstrualStartDate,
            today: Date()
        )
    }

    func autoCloseOpenMenstruationIfNeeded(activeMenstrualStartDate: Date?) async throws -> Bool {
        guard let activeMenstrualStartDate else { return false }
        let openRecord = MenstrualRecord(
            type: .menstrualRecord,
            startDate: calendar.startOfDay(for: activeMenstrualStartDate),
            endDate: nil
        )
        let predictedPeriodLength = menstrualOverview.prediction?.predictedPeriodLength
            ?? MenstrualPredictionEngine.Config.defaultPeriodLength

        if let closedRecord = openPeriodAutoCloser.tryAutoClose(
            openRecord: openRecord,
            predictedPeriodLength: predictedPeriodLength,
            referenceDate: Date(),
            calendar: calendar
        ) {
            // 자동 종료 조건 충족: 확정된 기록 저장, 이전 open record 범위까지 삭제
            try await saveMenstrualRecord(closedRecord, deleteThrough: Date())
            return true
        }

        // 자동 종료 조건 미충족: 진행 중인 월경을 HealthKit에 갱신 (startDate~오늘)
        try await saveMenstrualRecord(openRecord, deleteThrough: Date())
        return false
    }
}

