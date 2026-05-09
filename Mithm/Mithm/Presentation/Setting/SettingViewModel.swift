//
//  SettingViewModel.swift
//  Mithm
//

import Foundation
import Combine

@MainActor
final class SettingViewModel: ObservableObject {

    @Published private(set) var calendarExportEnabled: Bool

    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        self.calendarExportEnabled = appState.userSetting.calendarExportEnabled

        appState.$userSetting
            .map(\.calendarExportEnabled)
            .removeDuplicates()
            .assign(to: &$calendarExportEnabled)
    }

    func setCalendarExportEnabled(_ enabled: Bool) {
        appState.saveCalendarExportEnabled(enabled)
    }
}
