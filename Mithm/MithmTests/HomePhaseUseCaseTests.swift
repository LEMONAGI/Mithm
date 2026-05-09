//
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

    @Test("진행 중 월경에서 오늘이 예상 종료일을 넘어서면 종료일이 오늘로 확장된다")
    func activeMenstrualExtendsEndDateWhenTodayExceedsPrediction() {
        let useCase = HomePhaseUseCaseImpl(
            calendar: calendar,
            defaultPeriodLength: 5
        )

        let window = useCase.execute(
            menstrualOverview: MenstrualOverview(),
            activeMenstrualStartDate: date("2026-03-10"),
            today: date("2026-03-20")
        )

        // 기본 5일 → 예상 종료일 3/14, 오늘 3/20이 넘어섰으므로 endDate는 3/20
        #expect(window.phase == .menstrual)
        #expect(window.startDate == date("2026-03-10"))
        #expect(window.endDate == date("2026-03-20"))
    }

    @Test("진행 중 월경에서 오늘이 예상 종료일과 같으면 종료일이 예상 종료일 그대로 유지된다")
    func activeMenstrualKeepsEndDateWhenTodayEqualsPrediction() {
        let useCase = HomePhaseUseCaseImpl(
            calendar: calendar,
            defaultPeriodLength: 5
        )

        let window = useCase.execute(
            menstrualOverview: MenstrualOverview(),
            activeMenstrualStartDate: date("2026-03-10"),
            today: date("2026-03-14")
        )

        // 기본 5일 → 예상 종료일 3/14, 오늘도 3/14이므로 endDate는 3/14
        #expect(window.phase == .menstrual)
        #expect(window.startDate == date("2026-03-10"))
        #expect(window.endDate == date("2026-03-14"))
    }

    @Test("오늘 종료한 월경 표시 기간은 종료일 당일 월경기를 유지한다")
    func endedTodayDisplayWindowKeepsMenstrualPhase() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)

        let window = useCase.execute(
            menstrualOverview: MenstrualOverview(),
            menstrualDisplayWindow: MenstrualDisplayWindow(
                startDate: date("2026-05-01"),
                endDate: date("2026-05-03")
            ),
            today: date("2026-05-03")
        )

        #expect(window.phase == .menstrual)
        #expect(window.startDate == date("2026-05-01"))
        #expect(window.endDate == date("2026-05-03"))
    }

    @Test("표시용 월경 기간이 없으면 종료 다음 날 기존 gap 규칙으로 난포기를 계산한다")
    func afterEndedDisplayWindowClearsUsesFollicularGap() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualRecord, "2026-05-01", "2026-05-03"),
                record(.ovulationFertileWindowPrediction, "2026-05-10", "2026-05-16"),
                record(.ovulationPrediction, "2026-05-15", "2026-05-15"),
                record(.menstrualPrediction, "2026-05-29", "2026-06-02")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            menstrualDisplayWindow: nil,
            today: date("2026-05-04")
        )

        #expect(window.phase == .follicular)
        #expect(window.startDate == date("2026-05-04"))
        #expect(window.endDate == date("2026-05-09"))
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

    @Test("황체기는 다음 월경 예측 시작 전날을 종료일로 사용한다")
    func lutealEndsOneDayBeforePredictedMenstrualStart() {
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

    @Test("배란기 종료 다음 날 황체기는 예측된 다음 월경 전날까지 표시된다")
    func lutealStartsAfterOvulationAndEndsBeforePredictedMenstrual() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualRecord, "2026-04-25", "2026-04-30"),
                record(.ovulationFertileWindowPrediction, "2026-05-02", "2026-05-08"),
                record(.ovulationPrediction, "2026-05-07", "2026-05-07"),
                record(.menstrualPrediction, "2026-05-21", "2026-05-25")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            activeMenstrualStartDate: nil,
            today: date("2026-05-09")
        )

        #expect(window.phase == .luteal)
        #expect(window.startDate == date("2026-05-09"))
        #expect(window.endDate == date("2026-05-20"))
    }

    @Test("사용자가 직접 시작하지 않으면 월경 예측 기간에 들어가도 월경기로 전환되지 않는다")
    func doesNotEnterMenstrualPhaseFromPredictionWithoutActiveStart() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualRecord, "2026-03-01", "2026-03-05"),
                record(.ovulationFertileWindowPrediction, "2026-03-12", "2026-03-18"),
                record(.menstrualPrediction, "2026-03-31", "2026-04-04")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            activeMenstrualStartDate: nil,
            today: date("2026-04-02")
        )

        #expect(window.phase == .luteal)
        #expect(window.startDate == date("2026-03-19"))
        #expect(window.endDate == date("2026-04-02"))
    }

    @Test("사용자가 직접 시작하지 않으면 다음 예측 배란기에 도달해도 배란기로 전환되지 않는다")
    func doesNotEnterNextCycleOvulationWithoutActiveStart() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualRecord, "2026-03-01", "2026-03-05"),
                record(.ovulationFertileWindowPrediction, "2026-03-12", "2026-03-18"),
                record(.menstrualPrediction, "2026-03-31", "2026-04-04"),
                record(.ovulationFertileWindowPrediction, "2026-04-12", "2026-04-18")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            activeMenstrualStartDate: nil,
            today: date("2026-04-14")
        )

        #expect(window.phase == .luteal)
        #expect(window.startDate == date("2026-03-19"))
        #expect(window.endDate == date("2026-04-14"))
    }

    @Test("사용자가 직접 시작하지 않으면 다음 예측 난포기에 도달해도 난포기로 전환되지 않는다")
    func doesNotEnterNextCycleFollicularWithoutActiveStart() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualRecord, "2026-03-01", "2026-03-05"),
                record(.ovulationFertileWindowPrediction, "2026-03-12", "2026-03-18"),
                record(.menstrualPrediction, "2026-03-31", "2026-04-04"),
                record(.ovulationFertileWindowPrediction, "2026-04-12", "2026-04-18"),
                record(.ovulationPrediction, "2026-04-15", "2026-04-15")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            activeMenstrualStartDate: nil,
            today: date("2026-04-08")
        )

        #expect(window.phase == .luteal)
        #expect(window.startDate == date("2026-03-19"))
        #expect(window.endDate == date("2026-04-08"))
    }

    @Test("사용자가 직접 시작하지 않으면 다음 예측 황체기에 도달해도 황체기로 전환되지 않는다")
    func doesNotResetLutealWindowForNextCycleWithoutActiveStart() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualRecord, "2026-03-01", "2026-03-05"),
                record(.ovulationFertileWindowPrediction, "2026-03-12", "2026-03-18"),
                record(.menstrualPrediction, "2026-03-31", "2026-04-04"),
                record(.ovulationFertileWindowPrediction, "2026-04-12", "2026-04-18")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            activeMenstrualStartDate: nil,
            today: date("2026-04-20")
        )

        #expect(window.phase == .luteal)
        #expect(window.startDate == date("2026-03-19"))
        #expect(window.endDate == date("2026-04-20"))
    }

    @Test("다음 사이클 시작 경계 이후의 예측 데이터는 현재 phase 계산에서 제외한다")
    func excludesPredictionsOnOrAfterNextCycleBoundary() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualRecord, "2026-03-10", "2026-03-14"),
                record(.ovulationFertileWindowPrediction, "2026-03-22", "2026-03-28"),
                record(.menstrualPrediction, "2026-04-10", "2026-04-14")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            activeMenstrualStartDate: nil,
            today: date("2026-04-11")
        )

        #expect(window.phase == .luteal)
        #expect(window.startDate == date("2026-03-29"))
        #expect(window.endDate == date("2026-04-11"))
    }

    @Test("이전 배란기가 있으면 어떤 구간에도 포함되지 않아도 그 시작점을 유지하며 황체기를 반환한다")
    func fallsBackToExtendedLutealWindowFromPreviousOvulation() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)
        let overview = MenstrualOverview(
            allRecords: [
                record(.menstrualRecord, "2026-03-01", "2026-03-05"),
                record(.ovulationFertileWindowPrediction, "2026-03-12", "2026-03-18"),
                record(.menstrualPrediction, "2026-03-31", "2026-04-04")
            ]
        )

        let window = useCase.execute(
            menstrualOverview: overview,
            activeMenstrualStartDate: nil,
            today: date("2026-04-06")
        )

        #expect(window.phase == .luteal)
        #expect(window.startDate == date("2026-03-19"))
        #expect(window.endDate == date("2026-04-06"))
    }

    @Test("이전 배란기도 없으면 기본값으로 오늘 하루 황체기를 반환한다")
    func fallsBackToTodayLutealWindow() {
        let useCase = HomePhaseUseCaseImpl(calendar: calendar)

        let window = useCase.execute(
            menstrualOverview: MenstrualOverview(),
            activeMenstrualStartDate: nil,
            today: date("2026-03-20")
        )

        #expect(window.phase == .luteal)
        #expect(window.startDate == date("2026-03-20"))
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
