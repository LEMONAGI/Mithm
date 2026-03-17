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
    private let openPeriodAutoCloser: OpenPeriodAutoCloser
    private var hasPerformedAutoCloseCheck = false

    // MARK: - Persistence

    private static let menstrualStartDateKey = "menstrualStartDate"

    private var menstrualStartDateString: String {
        get { UserDefaults.standard.string(forKey: Self.menstrualStartDateKey) ?? "" }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.menstrualStartDateKey)
            isMenstruating = !newValue.isEmpty
            recomputePhaseWindow()
        }
    }

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        appState: AppState,
        calendar: Calendar = .current,
        menstrualRecordUseCase: MenstrualRecordUseCase,
        homePhaseUseCase: HomePhaseUseCase,
        openPeriodAutoCloser: OpenPeriodAutoCloser
    ) {
        self.appState = appState
        self.calendar = calendar
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.homePhaseUseCase = homePhaseUseCase
        self.openPeriodAutoCloser = openPeriodAutoCloser

        let storedString = UserDefaults.standard.string(forKey: Self.menstrualStartDateKey) ?? ""
        self.isMenstruating = !storedString.isEmpty

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
    }

    private func recomputePhaseWindow() {
        currentPhaseWindow = homePhaseUseCase.execute(
            menstrualOverview: appState.menstrualOverview,
            activeMenstrualStartDate: menstrualStartDate,
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

        if isPickingEndDate, let start = menstrualStartDate {
            return start...today
        }

        return Date.distantPast...today
    }

    // MARK: - Public Actions

    func startMenstruation(startDate: Date) async {
        let normalizedStart = calendar.startOfDay(for: startDate)
        menstrualStartDateString = FormatterUtility.iso8601.string(from: normalizedStart)

        let openRecord = MenstrualRecord(
            type: .menstrualRecord,
            startDate: normalizedStart,
            endDate: nil
        )
        do {
            try await saveMenstrualRecord(openRecord)
        } catch {
            appState.menstrualRecordError = error
        }
    }

    func endMenstruation(endDate: Date) async {
        guard let startDate = menstrualStartDate else { return }
        let normalizedEndDate = max(calendar.startOfDay(for: endDate), startDate)

        let record = MenstrualRecord(
            type: .menstrualRecord,
            startDate: startDate,
            endDate: normalizedEndDate
        )

        do {
            try await saveMenstrualRecord(record, deleteThrough: Date())
            menstrualStartDateString = ""
        } catch {
            appState.menstrualRecordError = error
        }
    }

    func autoCloseOpenMenstruationIfNeeded() async {
        guard !hasPerformedAutoCloseCheck else { return }
        hasPerformedAutoCloseCheck = true

        do {
            let didAutoClose = try await performAutoClose()
            if didAutoClose {
                menstrualStartDateString = ""
            }
        } catch {
            appState.menstrualRecordError = error
        }
    }

    // MARK: - Private Helpers

    private var menstrualStartDate: Date? {
        guard let date = FormatterUtility.iso8601.date(from: menstrualStartDateString) else {
            return nil
        }
        return calendar.startOfDay(for: date)
    }

    private var earliestPredictedMenstrualDate: Date? {
        let predictedRecords = appState.menstrualOverview.allRecords
            .filter { $0.type == .menstrualPrediction }
        let targetIndex = isMenstruating ? 1 : 0
        guard predictedRecords.indices.contains(targetIndex) else { return nil }
        return predictedRecords[targetIndex].startDate
    }

    private func saveMenstrualRecord(
        _ record: MenstrualRecord,
        deleteFrom: Date? = nil,
        deleteThrough: Date? = nil
    ) async throws {
        try await menstrualRecordUseCase.saveMenstrualRecored(
            record,
            deleteFrom: deleteFrom,
            deleteThrough: deleteThrough
        )
        try await appState.refreshMenstrualData()
    }

    private func performAutoClose() async throws -> Bool {
        guard let activeMenstrualStartDate = menstrualStartDate else { return false }
        let openRecord = MenstrualRecord(
            type: .menstrualRecord,
            startDate: calendar.startOfDay(for: activeMenstrualStartDate),
            endDate: nil
        )
        let predictedPeriodLength = appState.menstrualOverview.prediction?.predictedPeriodLength
            ?? MenstrualPredictionEngine.Config.defaultPeriodLength

        if let closedRecord = openPeriodAutoCloser.tryAutoClose(
            openRecord: openRecord,
            predictedPeriodLength: predictedPeriodLength,
            referenceDate: Date(),
            calendar: calendar
        ) {
            try await saveMenstrualRecord(closedRecord, deleteThrough: Date())
            return true
        }

        try await saveMenstrualRecord(openRecord, deleteThrough: Date())
        return false
    }
}
