//
//  CycleSettingViewModel.swift
//  Mithm
//

import Foundation
import Combine

@MainActor
final class CycleSettingViewModel: ObservableObject {

    @Published var cycleLength: Int
    @Published var periodLength: Int

    let cycleLengthRange = 15...60
    let periodLengthRange = 1...10

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        let input = appState.userSetting.menstrualUserInput
        self.cycleLength = max(15, min(input?.cycleLength ?? 28, 60))
        self.periodLength = max(1, min(input?.periodLength ?? 5, 10))
    }

    func reset() {
        let input = appState.userSetting.menstrualUserInput
        cycleLength = max(15, min(input?.cycleLength ?? 28, 60))
        periodLength = max(1, min(input?.periodLength ?? 5, 10))
    }

    func save() {
        appState.saveMenstrualUserInput(
            MenstrualUserInput(
                cycleLength: cycleLength,
                periodLength: periodLength
            )
        )
    }
}
