//
//  UserSettingUseCaseImpl.swift
//  Mithm
//
//  Created by YunhakLee on 3/15/26.
//

import Foundation

struct UserSettingUseCaseImpl: UserSettingUseCase {

    private let userSettingRepository: UserSettingRepository

    init(userSettingRepository: UserSettingRepository) {
        self.userSettingRepository = userSettingRepository
    }

    // MARK: - Load

    func loadMenstrualUserInput() -> MenstrualUserInput? {
        userSettingRepository.loadMenstrualUserInput()
    }

    func loadCalendarExportEnabled() -> Bool {
        userSettingRepository.loadCalendarExportEnabled()
    }

    func loadUserInputMode() -> UserInputMode? {
        userSettingRepository.loadUserInputMode()
    }

    func loadHasCompletedOnboarding() -> Bool {
        userSettingRepository.loadHasCompletedOnboarding()
    }

    // MARK: - Save

    func saveMenstrualUserInput(_ input: MenstrualUserInput) {
        userSettingRepository.saveMenstrualUserInput(input)
    }

    func saveCalendarExportEnabled(_ enabled: Bool) {
        userSettingRepository.saveCalendarExportEnabled(enabled)
    }

    func saveUserInputMode(_ mode: UserInputMode) {
        userSettingRepository.saveUserInputMode(mode)
    }

    func saveHasCompletedOnboarding(_ completed: Bool) {
        userSettingRepository.saveHasCompletedOnboarding(completed)
    }
}
