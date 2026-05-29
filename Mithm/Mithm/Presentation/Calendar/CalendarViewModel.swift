//
//  CalendarViewModel.swift
//  Mithm
//

import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {

    @Published private var menstrualOverview: MenstrualOverview
    @Published private(set) var menstrualRecordRows: [MenstrualRecordRow] = []
    @Published private(set) var isEditingMenstrualRecord = false

    private let appState: AppState
    private let cycleCalendarUseCase: CycleCalendarUseCase
    private let menstrualRecordEditingUseCase: MenstrualRecordEditingUseCase
    private let calendar: Calendar
    private var cancellables = Set<AnyCancellable>()

    init(
        appState: AppState,
        cycleCalendarUseCase: CycleCalendarUseCase,
        menstrualRecordEditingUseCase: MenstrualRecordEditingUseCase,
        calendar: Calendar = .current
    ) {
        self.appState = appState
        self.cycleCalendarUseCase = cycleCalendarUseCase
        self.menstrualRecordEditingUseCase = menstrualRecordEditingUseCase
        self.calendar = calendar
        self.menstrualOverview = appState.menstrualOverview
        self.menstrualRecordRows = Self.makeMenstrualRecordRows(
            overview: appState.menstrualOverview,
            calendar: calendar
        )

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

    func updateMenstrualRecord(
        _ row: MenstrualRecordRow,
        startDate: Date,
        endDate: Date
    ) async -> Bool {
        isEditingMenstrualRecord = true
        defer { isEditingMenstrualRecord = false }

        do {
            try await menstrualRecordEditingUseCase.update(
                originalRecord: row.record,
                startDate: startDate,
                endDate: endDate
            )
            try await appState.refreshMenstrualData()
            return true
        } catch {
            appState.menstrualRecordError = error
            return false
        }
    }

    func deleteMenstrualRecord(_ row: MenstrualRecordRow) async -> Bool {
        isEditingMenstrualRecord = true
        defer { isEditingMenstrualRecord = false }

        do {
            try await menstrualRecordEditingUseCase.delete(row.record)
            try await appState.refreshMenstrualData()
            return true
        } catch {
            appState.menstrualRecordError = error
            return false
        }
    }

    private func observeAppState() {
        appState.$menstrualOverview
            .receive(on: DispatchQueue.main)
            .sink { [weak self] overview in
                self?.menstrualOverview = overview
                guard let self else { return }
                self.menstrualRecordRows = Self.makeMenstrualRecordRows(
                    overview: overview,
                    calendar: self.calendar
                )
            }
            .store(in: &cancellables)
    }

    static func makeMenstrualRecordRows(
        overview: MenstrualOverview,
        calendar: Calendar
    ) -> [MenstrualRecordRow] {
        let records = overview.actualRecords
            .filter { $0.type == .menstrualRecord }
            .sorted { lhs, rhs in
                if lhs.startDate == rhs.startDate {
                    return (lhs.endDate ?? lhs.startDate) < (rhs.endDate ?? rhs.startDate)
                }
                return lhs.startDate < rhs.startDate
            }

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy.MM.dd"

        let rows = records.enumerated().map { index, record in
            let nextRecord = records.indices.contains(index + 1)
                ? records[index + 1]
                : nil
            let cycleLength = cycleLength(
                from: record,
                to: nextRecord,
                fallback: overview.prediction?.predictedCycleLength,
                calendar: calendar
            )
            let periodLength = record.dayCount(calendar: calendar)

            return MenstrualRecordRow(
                record: record,
                startDateText: dateFormatter.string(from: record.startDate),
                cycleLengthText: dayText(cycleLength),
                periodLengthText: dayText(periodLength),
                calendar: calendar
            )
        }

        return Array(rows.reversed())
    }

    private static func cycleLength(
        from record: MenstrualRecord,
        to nextRecord: MenstrualRecord?,
        fallback: Int?,
        calendar: Calendar
    ) -> Int? {
        guard let nextRecord else { return fallback }
        let startDate = calendar.startOfDay(for: record.startDate)
        let nextStartDate = calendar.startOfDay(for: nextRecord.startDate)
        return calendar.dateComponents(
            [.day],
            from: startDate,
            to: nextStartDate
        ).day
    }

    private static func dayText(_ days: Int?) -> String {
        guard let days else { return "-" }
        return String(format: String(localized: "calendar.stats.day_value.format"), days)
    }
}

struct MenstrualRecordRow: Identifiable, Hashable {
    let id: String
    let record: MenstrualRecord
    let startDateText: String
    let cycleLengthText: String
    let periodLengthText: String

    init(
        record: MenstrualRecord,
        startDateText: String,
        cycleLengthText: String,
        periodLengthText: String,
        calendar: Calendar = .current
    ) {
        self.record = record
        self.startDateText = startDateText
        self.cycleLengthText = cycleLengthText
        self.periodLengthText = periodLengthText

        let startDate = calendar.startOfDay(for: record.startDate).timeIntervalSince1970
        let endDate = (
            record.endDate.map { calendar.startOfDay(for: $0) }
                ?? calendar.startOfDay(for: record.startDate)
        ).timeIntervalSince1970
        self.id = "\(record.type.typeString)-\(startDate)-\(endDate)"
    }
}
