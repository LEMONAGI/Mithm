//
//  HomeViewModel.swift
//  Mithm
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var currentPhaseWindow: PhaseWindow
    @Published private(set) var isMenstruating: Bool = false
    @Published private(set) var showsMenstrualEndAction: Bool = false

    enum EndMenstruationAlertKind: Equatable {
        case endsToday
        case recorded
    }

    struct EndMenstruationResult: Equatable {
        let didRecord: Bool
        let completionAlertKind: EndMenstruationAlertKind?
    }

    // MARK: - Dependencies

    private let appState: AppState
    private let calendar: Calendar
    private let recordCurrentMenstrualPeriodUseCase: RecordCurrentMenstrualPeriodUseCase
    private let homePhaseUseCase: HomePhaseUseCase
    private let now: () -> Date

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        appState: AppState,
        calendar: Calendar = .current,
        recordCurrentMenstrualPeriodUseCase: RecordCurrentMenstrualPeriodUseCase,
        homePhaseUseCase: HomePhaseUseCase,
        now: @escaping () -> Date = Date.init
    ) {
        self.appState = appState
        self.calendar = calendar
        self.recordCurrentMenstrualPeriodUseCase = recordCurrentMenstrualPeriodUseCase
        self.homePhaseUseCase = homePhaseUseCase
        self.now = now
        self.isMenstruating = appState.currentMenstrualStatus.isActive
        self.showsMenstrualEndAction = appState.currentMenstrualStatus.displayWindow != nil

        self.currentPhaseWindow = PhaseWindow(
            phase: .luteal,
            startDate: Date(),
            endDate: Date()
        )

        observeAppState()
    }

    // MARK: - Observation

    private func observeAppState() {
        appState.$menstrualOverview
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.recomputePhaseWindow()
            }
            .store(in: &cancellables)

        appState.$currentMenstrualStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isMenstruating = status.isActive
                self?.showsMenstrualEndAction = status.displayWindow != nil
                self?.recomputePhaseWindow()
            }
            .store(in: &cancellables)
    }

    private func recomputePhaseWindow() {
        currentPhaseWindow = homePhaseUseCase.execute(
            menstrualOverview: appState.menstrualOverview,
            menstrualDisplayWindow: appState.currentMenstrualStatus.displayWindow,
            today: now()
        )
    }

    // MARK: - Computed Properties (View용)

    var currentPhase: PhaseType {
        currentPhaseWindow.phase
    }

    var currentPhasePresentation: PhasePresentation {
        currentPhase.presentation
    }

    var currentPhaseDateRangeString: String {
        let startDate = FormatterUtility.homePhaseRange.string(from: currentPhaseWindow.startDate)
        let endDate = FormatterUtility.homePhaseRange.string(from: currentPhaseWindow.endDate)
        return String(format: String(localized: "home.phase_range.format"), startDate, endDate)
    }

    var nextMenstrualString: String {
        guard let nextDate = earliestPredictedMenstrualDate else { return "-" }
        let today = calendar.startOfDay(for: now())
        let target = calendar.startOfDay(for: nextDate)
        let days = calendar.dateComponents([.day], from: today, to: target).day ?? 0

        let dateStr = FormatterUtility.homeNextMenstrual.string(from: nextDate)

        let dDay: String
        if days == 0 {
            dDay = String(localized: "home.next_menstrual.d_day")
        } else if days > 0 {
            dDay = String(format: String(localized: "home.next_menstrual.d_minus.format"), days)
        } else {
            dDay = String(format: String(localized: "home.next_menstrual.d_plus.format"), abs(days))
        }

        return String(format: String(localized: "home.next_menstrual.date_and_d_day.format"), dateStr, dDay)
    }

    func selectableDateRange(isPickingEndDate: Bool) -> ClosedRange<Date> {
        let today = calendar.startOfDay(for: now())

        if isPickingEndDate,
           let start = appState.currentMenstrualStatus.activeStartDate
            ?? appState.currentMenstrualStatus.displayWindow?.startDate {
            return start...today
        }

        return Date.distantPast...today
    }

    // MARK: - Public Actions

    func startMenstruation(startDate: Date) async {
        do {
            try await recordCurrentMenstrualPeriodUseCase.start(on: startDate)
            try await appState.refreshMenstrualData()
        } catch {
            appState.menstrualRecordError = error
        }
    }

    func endMenstruation(endDate: Date) async -> EndMenstruationResult {
        do {
            let didEnd = try await recordCurrentMenstrualPeriodUseCase.end(
                on: endDate,
                currentStatus: appState.currentMenstrualStatus
            )
            if didEnd {
                refreshMenstrualDataAfterRecording()
            }
            return EndMenstruationResult(
                didRecord: didEnd,
                completionAlertKind: completionAlertKind(
                    didRecord: didEnd,
                    endDate: endDate
                )
            )
        } catch {
            appState.menstrualRecordError = error
            return EndMenstruationResult(
                didRecord: false,
                completionAlertKind: nil
            )
        }
    }

    // MARK: - Private Helpers

    private func refreshMenstrualDataAfterRecording() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await appState.refreshMenstrualData()
            } catch {
                appState.menstrualRecordError = error
            }
        }
    }

    private func completionAlertKind(
        didRecord: Bool,
        endDate: Date
    ) -> EndMenstruationAlertKind? {
        guard didRecord else { return nil }
        return calendar.isDate(endDate, inSameDayAs: now())
            ? .endsToday
            : .recorded
    }

    private var earliestPredictedMenstrualDate: Date? {
        let predictedRecords = appState.menstrualOverview.allRecords
            .filter { $0.type == .menstrualPrediction }
        let targetIndex = isMenstruating ? 1 : 0
        guard predictedRecords.indices.contains(targetIndex) else { return nil }
        return predictedRecords[targetIndex].startDate
    }
}
