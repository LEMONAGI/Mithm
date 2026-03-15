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
    @Published var menstrualRecord = MenstrualRecordState()
    @Published var userSetting = UserSettingState()

    private let menstrualRecordUseCase: MenstrualRecordUseCase
    private let userSettingRepository: UserSettingRepository

    init(
        menstrualRecordUseCase: MenstrualRecordUseCase,
        userSettingRepository: UserSettingRepository
    ) {
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.userSettingRepository = userSettingRepository
    }

    // MARK: - Load

    func loadMenstrualRecords() async {
        menstrualRecord.loadState = .loading
        do {
            let records = try await menstrualRecordUseCase.fetchMenstrualRecords()
            menstrualRecord.loadState = .loaded(records)
        } catch {
            menstrualRecord.loadState = .failed(error)
        }
    }

    func loadUserSettings() {
        userSetting = UserSettingState(
            menstrualUserInput: userSettingRepository.loadMenstrualUserInput(),
            calendarExportEnabled: userSettingRepository.loadCalendarExportEnabled(),
            userInputMode: userSettingRepository.loadUserInputMode()
        )
    }

    // MARK: - Save

    func saveMenstrualRecord(_ record: MenstrualRecord) async throws {
        try await menstrualRecordUseCase.saveMenstrualRecored(record)
        await loadMenstrualRecords()
    }
}

// MARK: - MenstrualRecordState

struct MenstrualRecordState {
    var loadState: LoadState<[MenstrualRecord]> = .notRequested
}

// MARK: - UserSettingState

struct UserSettingState {
    var menstrualUserInput: MenstrualUserInput?
    var calendarExportEnabled: Bool
    var userInputMode: UserInputMode?

    init(
        menstrualUserInput: MenstrualUserInput? = nil,
        calendarExportEnabled: Bool = false,
        userInputMode: UserInputMode? = nil
    ) {
        self.menstrualUserInput = menstrualUserInput
        self.calendarExportEnabled = calendarExportEnabled
        self.userInputMode = userInputMode
    }
}

// MARK: - LoadState

enum LoadState<T> {
    case notRequested
    case loading
    case loaded(T)
    case failed(Error)
}

