//
//  CalendarView.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let dayOfWeekSymbols = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Title
                Text("캘린더")
                    .font(.pretendardBold(36))
                    .foregroundStyle(.textPrimary)
                    .padding(.bottom, 12)

                // Legend
                legendView
                    .padding(.bottom, 16)

                // Calendar Card
                calendarCard
                    .padding(.bottom, 24)

                // Stats
                statsView
                    .padding(.bottom, 24)

                // Button
                recordButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 26)
        }
    }
}

// MARK: - Subviews

extension CalendarView {

    private var legendView: some View {
        HStack(spacing: 16) {
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.accentTeal)
                    .frame(width: 8, height: 8)
                Text("배란기")
                    .font(.pretendardMedium(14))
                    .foregroundStyle(.textPrimary)
            }
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.primaryOrange)
                    .frame(width: 8, height: 8)
                Text("월경기")
                    .font(.pretendardMedium(14))
                    .foregroundStyle(.textPrimary)
            }
        }
    }

    private var calendarCard: some View {
        VStack(spacing: 0) {
            // Month Header
            monthHeader
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

            // Day of week header
            dayOfWeekHeader
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

            // Days grid
            daysGrid
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    private var monthHeader: some View {
        HStack {
            Button {
                moveMonth(by: 0) // tap on title — no-op or future picker
            } label: {
                HStack(spacing: 4) {
                    Text(monthYearString)
                        .font(.pretendardBold(20))
                        .foregroundStyle(.textPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                }
            }

            Spacer()

            HStack(spacing: 20) {
                Button { moveMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                }
                Button { moveMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                }
            }
        }
    }

    private var dayOfWeekHeader: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
            ForEach(dayOfWeekSymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.pretendardMedium(12))
                    .foregroundStyle(Color(.systemGray2))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: some View {
        let days = daysForGrid()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                dayCell(for: date)
            }
        }
    }

    private var statsView: some View {
        VStack(spacing: 8) {
            statRow(title: "평균 월경 기간", value: averagePeriodLength, unit: "일")
            statRow(title: "평균 월경 주기", value: averageCycleLength, unit: "일")
        }
    }

    private func statRow(title: String, value: Int?, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.pretendardMedium(16))
                .foregroundStyle(.textPrimary)
            Spacer()
            if let value {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(value)")
                        .font(.pretendardBold(28))
                        .foregroundStyle(.textPrimary)
                    Text(unit)
                        .font(.pretendardBold(16))
                        .foregroundStyle(.textPrimary)
                }
            } else {
                Text("-")
                    .font(.pretendardBold(28))
                    .foregroundStyle(.textPrimary)
            }
        }
    }

    private var recordButton: some View {
        Button {
            // TODO: Navigate to record list
        } label: {
            Text("월경 기록 확인하기")
                .font(.pretendardSemiBold(16))
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(.systemGray6))
                )
        }
    }
}

// MARK: - Day Cell

extension CalendarView {

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let dayNumber = calendar.component(.day, from: date)
        let isCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)

        if isCurrentMonth {
            let style = dayStyle(for: date)
            Text("\(dayNumber)")
                .font(style.font)
                .foregroundStyle(style.textColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(style.backgroundColor)
                )
        } else {
            Text("\(dayNumber)")
                .font(.pretendardRegular(16))
                .foregroundStyle(Color(.systemGray3))
                .frame(width: 40, height: 40)
        }
    }

    private struct DayCellStyle {
        let textColor: Color
        let backgroundColor: Color
        let font: Font
    }

    private func dayStyle(for date: Date) -> DayCellStyle {
        let allRecords = loadedRecords
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())

        let isMenstrual = allRecords.contains { r in
            (r.type == .menstrualRecord || r.type == .menstrualPrediction)
            && dateIsInRange(day, start: r.startDate, end: r.endDate)
        }

        let isOvulationDay = allRecords.contains { r in
            (r.type == .ovulationEstimated || r.type == .ovulationPrediction)
            && dateIsInRange(day, start: r.startDate, end: r.endDate)
        }

        let isFertileWindow = allRecords.contains { r in
            (r.type == .ovulationFertileWindowEstimated || r.type == .ovulationFertileWindowPrediction)
            && dateIsInRange(day, start: r.startDate, end: r.endDate)
        }

        if isMenstrual {
            return DayCellStyle(
                textColor: .primaryOrange,
                backgroundColor: Color.primaryOrange.opacity(0.15),
                font: .pretendardSemiBold(16)
            )
        } else if isOvulationDay {
            return DayCellStyle(
                textColor: .white,
                backgroundColor: .accentTeal,
                font: .pretendardBold(16)
            )
        } else if isFertileWindow {
            return DayCellStyle(
                textColor: .accentTeal,
                backgroundColor: .clear,
                font: .pretendardSemiBold(16)
            )
        } else if calendar.isDate(day, inSameDayAs: today) {
            return DayCellStyle(
                textColor: .textPrimary,
                backgroundColor: Color.accentTeal.opacity(0.12),
                font: .pretendardSemiBold(16)
            )
        } else {
            return DayCellStyle(
                textColor: .textPrimary,
                backgroundColor: .clear,
                font: .pretendardRegular(16)
            )
        }
    }

    private func dateIsInRange(_ date: Date, start: Date, end: Date?) -> Bool {
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end ?? start)
        return date >= s && date <= e
    }
}

// MARK: - Calendar Logic

extension CalendarView {

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: displayedMonth)
    }

    private func moveMonth(by value: Int) {
        guard value != 0,
              let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth)
        else { return }
        displayedMonth = newMonth
    }

    private static let gridCellCount = 35 // 5 rows × 7 columns

    private func daysForGrid() -> [Date] {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDayOfMonth = calendar.date(from: components) else { return [] }

        // Sunday = 1, so leading days from previous month = firstWeekday - 1
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingDays = firstWeekday - 1

        // Grid starts this many days before the 1st
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: firstDayOfMonth)
        else { return [] }

        return (0..<Self.gridCellCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: gridStart)
        }
    }

    private var loadedRecords: [MenstrualRecord] {
        if case .loaded(let records) = appState.menstrualRecord.loadState {
            return records
        }
        return []
    }
}

// MARK: - Stats Logic

extension CalendarView {

    private var averagePeriodLength: Int? {
        let actual = loadedRecords.filter {
            $0.type == MenstrualRecordType.menstrualRecord && $0.endDate != nil
        }
        let dayCounts = actual.compactMap { $0.dayCount }
        guard !dayCounts.isEmpty else { return nil }
        return dayCounts.reduce(0, +) / dayCounts.count
    }

    private var averageCycleLength: Int? {
        let actual = loadedRecords
            .filter { $0.type == MenstrualRecordType.menstrualRecord && $0.endDate != nil }
            .sorted { $0.startDate < $1.startDate }
        guard actual.count >= 2 else { return nil }

        var cycleLengths: [Int] = []
        for i in 1..<actual.count {
            let prev = calendar.startOfDay(for: actual[i - 1].startDate)
            let curr = calendar.startOfDay(for: actual[i].startDate)
            let days = calendar.dateComponents([.day], from: prev, to: curr).day ?? 0
            if days > 0 {
                cycleLengths.append(days)
            }
        }
        guard !cycleLengths.isEmpty else { return nil }
        return cycleLengths.reduce(0, +) / cycleLengths.count
    }
}

#Preview {
    CalendarView()
        .environmentObject(AppDIContainer.makeAppState())
}
