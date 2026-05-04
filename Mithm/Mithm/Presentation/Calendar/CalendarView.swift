//
//  CalendarView.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var calendarViewModel: CalendarViewModel
    @State private var displayedMonth: Date = Date()
    @State private var showMonthPicker = false

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
                showMonthPicker.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text(monthYearString)
                        .font(.pretendardBold(20))
                        .foregroundStyle(.textPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                }
            }
            .popover(isPresented: $showMonthPicker) {
                monthYearPickerPopover
                    .presentationCompactAdaptation(.popover)
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
                Text(LocalizedStringKey(symbol))
                    .font(.pretendardMedium(12))
                    .foregroundStyle(Color(.systemGray2))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: some View {
        let days = calendarViewModel.makeMonth(
            displayedMonth: displayedMonth
        ).days
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.date) { day in
                dayCell(for: day)
            }
        }
    }

    private var statsView: some View {
        VStack(spacing: 8) {
            statRow(title: "현재 월경 기간", value: calendarViewModel.predictedPeriodLength, unit: "일")
            statRow(title: "현재 월경 주기", value: calendarViewModel.predictedCycleLength, unit: "일")
        }
    }

    private func statRow(title: LocalizedStringKey, value: Int?, unit: LocalizedStringKey) -> some View {
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

    private var monthYearPickerPopover: some View {
        let currentYear = calendar.component(.year, from: Date())
        let years = Array((currentYear - 80)...(currentYear + 1))
        let months = Array(1...12)

        return HStack(spacing: 0) {
            Picker("년", selection: Binding(
                get: { calendar.component(.year, from: displayedMonth) },
                set: { newYear in
                    var components = calendar.dateComponents([.year, .month, .day], from: displayedMonth)
                    components.year = newYear
                    components.day = 1
                    if let date = calendar.date(from: components) {
                        displayedMonth = date
                    }
                }
            )) {
                ForEach(years, id: \.self) { year in
                    Text(String(format: String(localized: "calendar.year.format"), year)).tag(year)
                }
            }
            .pickerStyle(.wheel)

            Picker("월", selection: Binding(
                get: { calendar.component(.month, from: displayedMonth) },
                set: { newMonth in
                    var components = calendar.dateComponents([.year, .month, .day], from: displayedMonth)
                    components.month = newMonth
                    components.day = 1
                    if let date = calendar.date(from: components) {
                        displayedMonth = date
                    }
                }
            )) {
                ForEach(months, id: \.self) { month in
                    Text(String(format: String(localized: "calendar.month.format"), month)).tag(month)
                }
            }
            .pickerStyle(.wheel)
        }
        .frame(width: 280, height: 200)
    }
}

// MARK: - Day Cell

extension CalendarView {

    @ViewBuilder
    private func dayCell(for day: CycleCalendarDay) -> some View {
        let dayNumber = calendar.component(.day, from: day.date)

        if day.isCurrentMonth {
            let style = dayStyle(for: day.kind)
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

    private func dayStyle(for kind: CycleDayKind) -> DayCellStyle {
        switch kind {
        case .menstrual:
            return DayCellStyle(
                textColor: .primaryOrange,
                backgroundColor: Color.primaryOrange.opacity(0.15),
                font: .pretendardSemiBold(16)
            )
        case .ovulationDay:
            return DayCellStyle(
                textColor: .white,
                backgroundColor: .accentTeal,
                font: .pretendardBold(16)
            )
        case .fertileWindow:
            return DayCellStyle(
                textColor: .accentTeal,
                backgroundColor: .clear,
                font: .pretendardSemiBold(16)
            )
        case .today:
            return DayCellStyle(
                textColor: .textPrimary,
                backgroundColor: Color.accentTeal.opacity(0.12),
                font: .pretendardSemiBold(16)
            )
        case .none:
            return DayCellStyle(
                textColor: .textPrimary,
                backgroundColor: .clear,
                font: .pretendardRegular(16)
            )
        }
    }
}

// MARK: - Calendar Logic

extension CalendarView {

    private var monthYearString: String {
        let year = calendar.component(.year, from: displayedMonth)
        let month = calendar.component(.month, from: displayedMonth)
        return String(format: String(localized: "calendar.month_year.format"), year, month)
    }

    private func moveMonth(by value: Int) {
        guard value != 0,
              let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth)
        else { return }
        displayedMonth = newMonth
    }

}

#Preview {
    let appState = AppDIContainer.makeAppState()
    CalendarView()
        .environmentObject(AppDIContainer.makeCalendarViewModel(appState: appState))
}
