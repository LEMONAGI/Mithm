//
//  CalendarViewModel.swift
//  Mithm
//

import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {

    @Published private var menstrualOverview: MenstrualOverview

    private let appState: AppState
    private let cycleCalendarUseCase: CycleCalendarUseCase
    private var cancellables = Set<AnyCancellable>()

    init(
        appState: AppState,
        cycleCalendarUseCase: CycleCalendarUseCase
    ) {
        self.appState = appState
        self.cycleCalendarUseCase = cycleCalendarUseCase
        self.menstrualOverview = appState.menstrualOverview

        observeAppState()
    }

    func makeMonth(displayedMonth: Date) -> CycleCalendarMonth {
        cycleCalendarUseCase.makeMonth(
            displayedMonth: displayedMonth,
            records: menstrualOverview.allRecords
        )
    }

    var predictedPeriodLength: Int? {
        menstrualOverview.prediction.flatMap { $0.predictedPeriodLength }
    }

    var predictedCycleLength: Int? {
        menstrualOverview.prediction.flatMap { $0.predictedCycleLength }
    }

    private func observeAppState() {
        appState.$menstrualOverview
            .receive(on: DispatchQueue.main)
            .sink { [weak self] overview in
                self?.menstrualOverview = overview
            }
            .store(in: &cancellables)
    }
}
