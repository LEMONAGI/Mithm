//
//  UserSettingState.swift
//  Mithm
//
//  Created by YunhakLee on 3/15/26.
//


import Foundation

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

enum MenstrualEpisodeClosedReason: String, Codable, Equatable {
    case userEnded
    case autoClosed
}

struct CurrentMenstrualEpisode: Codable, Equatable {
    let startDate: Date
    let endDate: Date?
    let closedReason: MenstrualEpisodeClosedReason?

    var isClosed: Bool {
        closedReason != nil
    }
}

struct MenstrualDisplayWindow: Equatable {
    let startDate: Date
    let endDate: Date?
}

struct CurrentMenstrualStatus: Equatable {
    let isActive: Bool
    let activeStartDate: Date?
    let latestStartDate: Date?
    let expectedEndDate: Date?
    let shouldAutoClose: Bool
    let displayWindow: MenstrualDisplayWindow?

    init(
        isActive: Bool,
        activeStartDate: Date?,
        latestStartDate: Date?,
        expectedEndDate: Date?,
        shouldAutoClose: Bool,
        displayWindow: MenstrualDisplayWindow? = nil
    ) {
        self.isActive = isActive
        self.activeStartDate = activeStartDate
        self.latestStartDate = latestStartDate
        self.expectedEndDate = expectedEndDate
        self.shouldAutoClose = shouldAutoClose
        self.displayWindow = displayWindow
    }

    static func inactive(
        latestStartDate: Date? = nil,
        expectedEndDate: Date? = nil,
        shouldAutoClose: Bool = false,
        displayWindow: MenstrualDisplayWindow? = nil
    ) -> CurrentMenstrualStatus {
        CurrentMenstrualStatus(
            isActive: false,
            activeStartDate: nil,
            latestStartDate: latestStartDate,
            expectedEndDate: expectedEndDate,
            shouldAutoClose: shouldAutoClose,
            displayWindow: displayWindow
        )
    }
}

protocol CurrentMenstrualEpisodeStore {
    func loadCurrentEpisode() -> CurrentMenstrualEpisode?
    func saveCurrentEpisode(_ episode: CurrentMenstrualEpisode)
    func clearCurrentEpisode()
}
