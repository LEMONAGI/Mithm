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

    var canSave: Bool {
        cycleLength != originalCycleLength || periodLength != originalPeriodLength
    }

    private let appState: AppState
    private var originalCycleLength: Int
    private var originalPeriodLength: Int

    init(appState: AppState) {
        self.appState = appState
        let values = Self.normalizedValues(from: appState.userSetting.menstrualUserInput)
        self.cycleLength = values.cycleLength
        self.periodLength = values.periodLength
        self.originalCycleLength = values.cycleLength
        self.originalPeriodLength = values.periodLength
    }

    func reset() {
        let values = Self.normalizedValues(from: appState.userSetting.menstrualUserInput)
        cycleLength = values.cycleLength
        periodLength = values.periodLength
        originalCycleLength = values.cycleLength
        originalPeriodLength = values.periodLength
    }

    func save() {
        guard canSave else {
            return
        }

        appState.saveMenstrualUserInput(
            MenstrualUserInput(
                cycleLength: cycleLength,
                periodLength: periodLength
            )
        )
        originalCycleLength = cycleLength
        originalPeriodLength = periodLength
    }

    private static func normalizedValues(
        from input: MenstrualUserInput?
    ) -> (cycleLength: Int, periodLength: Int) {
        (
            cycleLength: max(15, min(input?.cycleLength ?? 28, 60)),
            periodLength: max(1, min(input?.periodLength ?? 5, 10))
        )
    }
}
