ㅇ//
//  HomePhaseUseCaseTests.swift
//  MithmTests
//
//  Created by Codex on 8/13/25.
//

import Foundation
import Testing
@testable import Mithm

struct HomePhaseUseCaseTests {
    private let calendar = HomePhaseTestCalendar.make()

    @Test("진행 중 월경은 예측값이 없으면 주입된 기본 월경 기간으로 종료일을 계산한다")
    func activeMenstrualUsesInjectedDefaultPeriodLength() {
        let useCase = HomePhaseUseCaseImpl(
            calendar: calendar,
            defaultPeriodLength: 7
        )

        let window = useCase.execute(
            menstrualOverview: MenstrualOverview(),
            activeMenstrualStartDate: date("2026-03-10"),
            today: date("2026-03-12")
        )

        #expect(window.phase == .menstrual)
        #expect(window.startDate == date("2026-03-10"))
        #expect(window.endDate == date("2026-03-16"))
    }

    @Test("난포기는 이전 월경기와 다음 배란기 사이의 날짜로 계산한다")
    func buildsFollicularWindowFromGap() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualRecord, "2026-03-01", "2026-03-05"),
                record(.ovulationFertileWindowPrediction, "2026-03-12", "2026-03-18"),
                record(.ovulationPrediction, "2026-03-17", "2026-03-17"),
                record(.menstrualPrediction, "2026-03-31", "2026-04-04")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            activeMenstrualStartDate: nil,
            today: date("2026-03-10")
        )

        #expect(window.phase == .follicular)
        #expect(window.startDate == date("2026-03-06"))
        #expect(window.endDate == date("2026-03-11"))
    }

    @Test("황체기는 이전 배란기와 다음 월경기 사이의 날짜로 계산한다")
    func buildsLutealWindowFromGap() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualRecord, "2026-03-01", "2026-03-05"),
                record(.ovulationFertileWindowPrediction, "2026-03-12", "2026-03-18"),
                record(.ovulationPrediction, "2026-03-17", "2026-03-17"),
                record(.menstrualPrediction, "2026-03-31", "2026-04-04")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            activeMenstrualStartDate: nil,
            today: date("2026-03-25")
        )

        #expect(window.phase == .luteal)
        #expect(window.startDate == date("2026-03-19"))
        #expect(window.endDate == date("2026-03-30"))
    }

    @Test("다음 월경기만 있으면 fallback으로 오늘부터 다음 월경 전날까지 황체기를 만든다")
    func fallbackUsesNextMenstrualWhenOnlyFutureBoundaryExists() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualPrediction, "2026-03-31", "2026-04-04")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            activeMenstrualStartDate: nil,
            today: date("2026-03-20")
        )

        #expect(window.phase == .luteal)
        #expect(window.startDate == date("2026-03-20"))
        #expect(window.endDate == date("2026-03-30"))
    }

    @Test("이전 월경기만 있으면 fallback으로 월경 종료 다음 날부터 오늘까지 난포기를 만든다")
    func fallbackUsesPreviousMenstrualWhenOnlyPastMenstrualExists() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualRecord, "2026-03-01", "2026-03-05")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            activeMenstrualStartDate: nil,
            today: date("2026-03-20")
        )

        #expect(window.phase == .follicular)
        #expect(window.startDate == date("2026-03-06"))
        #expect(window.endDate == date("2026-03-20"))
    }

    private func record(_ type: MenstrualRecordType, _ start: String, _ end: String?) -> MenstrualRecord {
        MenstrualRecord(
            type: type,
            startDate: date(start),
            endDate: end.map(date)
        )
    }

    private func date(_ value: String) -> Date {
        HomePhaseTestCalendar.date(value, calendar: calendar)
    }
}

private enum HomePhaseTestCalendar {
    static func make() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static func date(_ value: String, calendar: Calendar) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}
