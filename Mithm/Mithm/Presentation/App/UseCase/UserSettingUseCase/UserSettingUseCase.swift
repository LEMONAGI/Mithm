//
//  UserSettingUseCase.swift
//  Mithm
//
//  Created by YunhakLee on 3/15/26.
//

protocol UserSettingUseCase {

    // MARK: - Load

    func loadMenstrualUserInput() -> MenstrualUserInput?
    func loadCalendarExportEnabled() -> Bool
    func loadUserInputMode() -> UserInputMode?
    func loadHasCompletedOnboarding() -> Bool

    // MARK: - Save

    func saveMenstrualUserInput(_ input: MenstrualUserInput)
    func saveCalendarExportEnabled(_ enabled: Bool)
    func saveUserInputMode(_ mode: UserInputMode)
    func saveHasCompletedOnboarding(_ completed: Bool)
}
