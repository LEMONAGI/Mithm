//
//  CycleCalendarUseCaseImpl.swift
//  Mithm
//

import Foundation

struct CycleCalendarUseCaseImpl: CycleCalendarUseCase {

    private static let gridCellCount = 42

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func makeMonth(
        displayedMonth: Date,
        records: [MenstrualRecord],
        today: Date = Date()
    ) -> CycleCalendarMonth {
        let days = datesForGrid(displayedMonth: displayedMonth).map { date in
            let isCurrentMonth = calendar.isDate(
                date,
                equalTo: displayedMonth,
                toGranularity: .month
            )
            let isToday = isCurrentMonth && calendar.isDate(date, inSameDayAs: today)
            return CycleCalendarDay(
                date: date,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                kind: isCurrentMonth
                    ? dayKind(for: date, records: records)
                    : .none
            )
        }

        return CycleCalendarMonth(
            displayedMonth: displayedMonth,
            days: days
        )
    }

    private func datesForGrid(displayedMonth: Date) -> [Date] {
        let components = calendar.dateComponents(
            [.year, .month],
            from: displayedMonth
        )
        guard let firstDayOfMonth = calendar.date(from: components) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingDays = firstWeekday - 1

        guard let gridStart = calendar.date(
            byAdding: .day,
            value: -leadingDays,
            to: firstDayOfMonth
        ) else {
            return []
        }

        return (0..<Self.gridCellCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: gridStart)
        }
    }

    private func dayKind(
        for date: Date,
        records: [MenstrualRecord]
    ) -> CycleDayKind {
        let day = calendar.startOfDay(for: date)

        let isMenstrual = records.contains { record in
            (record.type == .menstrualRecord || record.type == .menstrualPrediction)
                && dateIsInRange(day, start: record.startDate, end: record.endDate)
        }

        let isOvulationDay = records.contains { record in
            (record.type == .ovulationEstimated || record.type == .ovulationPrediction)
                && dateIsInRange(day, start: record.startDate, end: record.endDate)
        }

        let isFertileWindow = records.contains { record in
            (
                record.type == .ovulationFertileWindowEstimated
                    || record.type == .ovulationFertileWindowPrediction
            ) && dateIsInRange(day, start: record.startDate, end: record.endDate)
        }

        if isMenstrual {
            return .menstrual
        } else if isOvulationDay {
            return .ovulationDay
        } else if isFertileWindow {
            return .fertileWindow
        } else {
            return .none
        }
    }

    private func dateIsInRange(
        _ date: Date,
        start: Date,
        end: Date?
    ) -> Bool {
        let startDate = calendar.startOfDay(for: start)
        let endDate = calendar.startOfDay(for: end ?? start)
        return date >= startDate && date <= endDate
    }
}
