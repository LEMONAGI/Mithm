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

    // MARK: - Dependencies

    private let appState: AppState
    private let calendar: Calendar
    private let menstrualRecordUseCase: MenstrualRecordUseCase
    private let homePhaseUseCase: HomePhaseUseCase
    private let currentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        appState: AppState,
        calendar: Calendar = .current,
        menstrualRecordUseCase: MenstrualRecordUseCase,
        homePhaseUseCase: HomePhaseUseCase,
        currentMenstrualEpisodeStore: CurrentMenstrualEpisodeStore
    ) {
        self.appState = appState
        self.calendar = calendar
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.homePhaseUseCase = homePhaseUseCase
        self.currentMenstrualEpisodeStore = currentMenstrualEpisodeStore
        self.isMenstruating = appState.currentMenstrualStatus.isActive

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
                self?.recomputePhaseWindow()
            }
            .store(in: &cancellables)
    }

    private func recomputePhaseWindow() {
        let activeStartDate = appState.currentMenstrualStatus.isActive
            ? appState.currentMenstrualStatus.activeStartDate
            : nil
        currentPhaseWindow = homePhaseUseCase.execute(
            menstrualOverview: appState.menstrualOverview,
            activeMenstrualStartDate: activeStartDate,
            today: Date()
        )
    }

    // MARK: - Computed Properties (View용)

    var currentPhase: PhaseType {
        currentPhaseWindow.phase
    }

    var currentPhaseDateRangeString: String {
        "\(FormatterUtility.homePhaseRange.string(from: currentPhaseWindow.startDate)) - \(FormatterUtility.homePhaseRange.string(from: currentPhaseWindow.endDate))"
    }

    var nextMenstrualString: String {
        guard let nextDate = earliestPredictedMenstrualDate else { return "-" }
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: nextDate)
        let days = calendar.dateComponents([.day], from: today, to: target).day ?? 0

        let dateStr = FormatterUtility.homeNextMenstrual.string(from: nextDate)

        let dDay: String
        if days == 0 {
            dDay = "D-Day"
        } else if days > 0 {
            dDay = "D-\(days)"
        } else {
            dDay = "D+\(abs(days))"
        }

        return "\(dateStr) · \(dDay)"
    }

    func selectableDateRange(isPickingEndDate: Bool) -> ClosedRange<Date> {
        let today = calendar.startOfDay(for: Date())

        if isPickingEndDate, let start = appState.currentMenstrualStatus.activeStartDate {
            return start...today
        }

        return Date.distantPast...today
    }

    // MARK: - Public Actions

    func startMenstruation(startDate: Date) async {
        let normalizedStart = calendar.startOfDay(for: startDate)

        let startRecord = MenstrualRecord(
            type: .menstrualRecord,
            startDate: normalizedStart,
            endDate: normalizedStart
        )
        do {
            try await menstrualRecordUseCase.saveMenstrualRecored(
                startRecord,
                deleteFrom: normalizedStart,
                deleteThrough: normalizedStart
            )
            currentMenstrualEpisodeStore.saveCurrentEpisode(
                CurrentMenstrualEpisode(
                    startDate: normalizedStart,
                    endDate: nil,
                    closedReason: nil
                )
            )
            try await appState.refreshMenstrualData()
        } catch {
            appState.menstrualRecordError = error
        }
    }

    func endMenstruation(endDate: Date) async {
        guard let startDate = appState.currentMenstrualStatus.activeStartDate else { return }
        let normalizedEndDate = max(calendar.startOfDay(for: endDate), startDate)

        let record = MenstrualRecord(
            type: .menstrualRecord,
            startDate: startDate,
            endDate: normalizedEndDate
        )

        do {
            try await menstrualRecordUseCase.saveMenstrualRecored(
                record,
                deleteFrom: startDate,
                deleteThrough: Date()
            )
            currentMenstrualEpisodeStore.saveCurrentEpisode(
                CurrentMenstrualEpisode(
                    startDate: startDate,
                    endDate: normalizedEndDate,
                    closedReason: .userEnded
                )
            )
            try await appState.refreshMenstrualData()
        } catch {
            appState.menstrualRecordError = error
        }
    }

    // MARK: - Private Helpers

    private var earliestPredictedMenstrualDate: Date? {
        let predictedRecords = appState.menstrualOverview.allRecords
            .filter { $0.type == .menstrualPrediction }
        let targetIndex = isMenstruating ? 1 : 0
        guard predictedRecords.indices.contains(targetIndex) else { return nil }
        return predictedRecords[targetIndex].startDate
    }
}
