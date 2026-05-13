//
//  SettingViewModel.swift
//  Mithm
//

import Foundation
import Combine

@MainActor
final class SettingViewModel: ObservableObject {

    @Published private(set) var calendarExportEnabled: Bool
    @Published private(set) var userInputMode: UserInputMode
    @Published private(set) var predictionMethodDraft: UserInputMode
    @Published private(set) var menstrualUserInput: MenstrualUserInput?

    var canSavePredictionMethodDraft: Bool {
        predictionMethodDraft != userInputMode
    }

    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        self.calendarExportEnabled = appState.userSetting.calendarExportEnabled
        self.userInputMode = appState.userSetting.userInputMode ?? .blendUserInput
        self.predictionMethodDraft = appState.userSetting.userInputMode ?? .blendUserInput
        self.menstrualUserInput = appState.userSetting.menstrualUserInput

        appState.$userSetting
            .map(\.calendarExportEnabled)
            .removeDuplicates()
            .assign(to: &$calendarExportEnabled)

        appState.$userSetting
            .map { $0.userInputMode ?? .blendUserInput }
            .removeDuplicates()
            .assign(to: &$userInputMode)

        appState.$userSetting
            .map(\.menstrualUserInput)
            .assign(to: &$menstrualUserInput)
    }

    func setCalendarExportEnabled(_ enabled: Bool) {
        appState.saveCalendarExportEnabled(enabled)
    }

    func setUserInputMode(_ mode: UserInputMode) {
        appState.saveUserInputMode(mode)
    }

    func resetPredictionMethodDraft() {
        predictionMethodDraft = userInputMode
    }

    func setPredictionMethodDraft(_ mode: UserInputMode) {
        predictionMethodDraft = mode
    }

    func savePredictionMethodDraft() {
        guard predictionMethodDraft != userInputMode else {
            return
        }
        setUserInputMode(predictionMethodDraft)
    }
}
