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
