//
//  CycleCalendarMonth.swift
//  Mithm
//

import Foundation

struct CycleCalendarMonth {
    let displayedMonth: Date
    let days: [CycleCalendarDay]
}

struct CycleCalendarDay: Hashable {
    let date: Date
    let isCurrentMonth: Bool
    let kind: CycleDayKind
}

enum CycleDayKind: Hashable {
    case none
    case today
    case menstrual
    case fertileWindow
    case ovulationDay
}
