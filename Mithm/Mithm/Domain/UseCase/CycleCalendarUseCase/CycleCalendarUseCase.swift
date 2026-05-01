//
//  CycleCalendarUseCase.swift
//  Mithm
//

import Foundation

/// 캘린더 월 그리드와 날짜별 월경/배란 표시 분류를 생성한다.
protocol CycleCalendarUseCase {
    func makeMonth(
        displayedMonth: Date,
        records: [MenstrualRecord],
        today: Date
    ) -> CycleCalendarMonth
}

extension CycleCalendarUseCase {
    func makeMonth(
        displayedMonth: Date,
        records: [MenstrualRecord]
    ) -> CycleCalendarMonth {
        makeMonth(
            displayedMonth: displayedMonth,
            records: records,
            today: Date()
        )
    }
}
