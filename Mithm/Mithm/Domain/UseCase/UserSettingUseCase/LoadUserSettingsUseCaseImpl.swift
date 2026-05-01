//
//  LoadUserSettingsUseCaseImpl.swift
//  Mithm
//

struct LoadUserSettingsUseCaseImpl: LoadUserSettingsUseCase {

    private let userSettingUseCase: UserSettingUseCase

    init(userSettingUseCase: UserSettingUseCase) {
        self.userSettingUseCase = userSettingUseCase
    }

    func execute() -> UserSettingState {
        UserSettingState(
            menstrualUserInput: userSettingUseCase.loadMenstrualUserInput(),
            calendarExportEnabled: userSettingUseCase.loadCalendarExportEnabled(),
            userInputMode: userSettingUseCase.loadUserInputMode()
        )
    }
}
