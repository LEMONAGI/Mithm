//
//  HomePhaseUseCaseImpl.swift
//  Mithm
//
//  Created by Codex on 8/13/25.
//

import Foundation

/// 홈 화면의 현재 phase를 "record 우선" 규칙으로 계산한다.
///
/// 월경기와 배란기는 해당 record의 날짜를 그대로 사용하고,
/// 난포기와 황체기는 인접한 두 record 사이의 빈 구간(gap)으로 계산한다.
///
/// 판정 순서는 다음과 같다.
/// 1. 진행 중 월경(AppStorage)
/// 2. 오늘이 포함된 월경 record
/// 3. 오늘이 포함된 배란기/배란 record
/// 4. 이전 월경기와 다음 배란기 사이 gap이면 난포기
/// 5. 이전 배란기와 다음 월경기 사이 gap이면 황체기
/// 6. 일부 경계만 존재할 때는 fallback 규칙으로 보정
struct HomePhaseUseCaseImpl: HomePhaseUseCase {
    private let calendar: Calendar
    private let defaultPeriodLength: Int

    // MARK: - Init

    init(
        calendar: Calendar = .current,
        defaultPeriodLength: Int = 5
    ) {
        self.calendar = calendar
        self.defaultPeriodLength = defaultPeriodLength
    }

    // MARK: - Public

    func execute(
        menstrualOverview: MenstrualOverview,
        activeMenstrualStartDate: Date?,
        today: Date = Date()
    ) -> PhaseWindow {
        let today = calendar.startOfDay(for: today)
        let allRecords = menstrualOverview.allRecords
        let menstrualRecords = allRecords.filter { $0.type == .menstrualRecord || $0.type == .menstrualPrediction }
        let ovulationRecords = allRecords.filter {
            $0.type == .ovulationEstimated
            || $0.type == .ovulationPrediction
            || $0.type == .ovulationFertileWindowEstimated
            || $0.type == .ovulationFertileWindowPrediction
        }
        let ovulationWindowRecords = ovulationRecords.filter {
            $0.type == .ovulationFertileWindowEstimated
            || $0.type == .ovulationFertileWindowPrediction
        }

        if let activeMenstrualWindow = makeActiveMenstrualWindow(
            activeMenstrualStartDate: activeMenstrualStartDate,
            predictedPeriodLength: menstrualOverview.prediction?.predictedPeriodLength
        ) {
            return activeMenstrualWindow
        }

        if let currentMenstrualRecord = menstrualRecords.first(where: { contains($0, day: today) }) {
            return PhaseWindow(
                phase: .menstrual,
                startDate: startDay(of: currentMenstrualRecord),
                endDate: endDay(of: currentMenstrualRecord)
            )
        }

        if let currentOvulationRecord = ovulationWindowRecords.first(where: { contains($0, day: today) })
            ?? ovulationRecords.first(where: { contains($0, day: today) }) {
            return PhaseWindow(
                phase: .ovulation,
                startDate: startDay(of: currentOvulationRecord),
                endDate: endDay(of: currentOvulationRecord)
            )
        }

        let previousMenstrualRecord = menstrualRecords.last(where: { endDay(of: $0) < today })
        let nextMenstrualRecord = menstrualRecords.first(where: { startDay(of: $0) > today })
        let previousOvulationRecord = ovulationWindowRecords.last(where: { endDay(of: $0) < today })
            ?? ovulationRecords.last(where: { endDay(of: $0) < today })
        let nextOvulationRecord = ovulationWindowRecords.first(where: { startDay(of: $0) > today })
            ?? ovulationRecords.first(where: { startDay(of: $0) > today })

        if let follicularWindow = makeFollicularWindow(
            after: previousMenstrualRecord,
            before: nextOvulationRecord,
            today: today
        ), follicularWindow.startDate <= today, today <= follicularWindow.endDate {
            return follicularWindow
        }

        if let lutealWindow = makeLutealWindow(
            after: previousOvulationRecord,
            before: nextMenstrualRecord,
            today: today
        ), lutealWindow.startDate <= today, today <= lutealWindow.endDate {
            return lutealWindow
        }

        return makeFallbackWindow(
            today: today,
            previousMenstrualRecord: previousMenstrualRecord,
            previousOvulationRecord: previousOvulationRecord,
            nextMenstrualRecord: nextMenstrualRecord,
            nextOvulationRecord: nextOvulationRecord
        )
    }

    // MARK: - Active Menstrual

    /// 사용자가 직접 시작한 진행 중 월경이 있으면,
    /// 예측 기간 또는 기본 기간을 사용해 월경기 구간을 만든다.
    private func makeActiveMenstrualWindow(
        activeMenstrualStartDate: Date?,
        predictedPeriodLength: Int?
    ) -> PhaseWindow? {
        guard let activeMenstrualStartDate else { return nil }

        let activeStartDate = calendar.startOfDay(for: activeMenstrualStartDate)
        let resolvedPeriodLength = predictedPeriodLength ?? defaultPeriodLength
        let predictedEndDate = calendar.date(
            byAdding: .day,
            value: max(resolvedPeriodLength - 1, 0),
            to: activeStartDate
        ) ?? activeStartDate

        return PhaseWindow(
            phase: .menstrual,
            startDate: activeStartDate,
            endDate: predictedEndDate
        )
    }

    // MARK: - Gap Window

    /// 난포기는 "이전 월경기 종료 다음 날 ~ 다음 배란기 시작 전날" 구간이다.
    private func makeFollicularWindow(
        after previousMenstrualRecord: MenstrualRecord?,
        before nextOvulationRecord: MenstrualRecord?,
        today: Date
    ) -> PhaseWindow? {
        makeGapWindow(
            phase: .follicular,
            after: previousMenstrualRecord,
            before: nextOvulationRecord,
            defaultAnchor: today
        )
    }

    /// 황체기는 "이전 배란기 종료 다음 날 ~ 다음 월경기 시작 전날" 구간이다.
    private func makeLutealWindow(
        after previousOvulationRecord: MenstrualRecord?,
        before nextMenstrualRecord: MenstrualRecord?,
        today: Date
    ) -> PhaseWindow? {
        makeGapWindow(
            phase: .luteal,
            after: previousOvulationRecord,
            before: nextMenstrualRecord,
            defaultAnchor: today
        )
    }

    /// 두 record 사이의 빈 구간을 phase window로 변환한다.
    ///
    /// `defaultAnchor`는 fallback 시점(today)과의 정합성을 맞추기 위한 기준값이다.
    private func makeGapWindow(
        phase: PhaseType,
        after previousRecord: MenstrualRecord?,
        before nextRecord: MenstrualRecord?,
        defaultAnchor: Date
    ) -> PhaseWindow? {
        guard let previousRecord, let nextRecord else { return nil }

        let startDate = calendar.date(byAdding: .day, value: 1, to: endDay(of: previousRecord)) ?? endDay(of: previousRecord)
        let endDate = calendar.date(byAdding: .day, value: -1, to: startDay(of: nextRecord)) ?? startDay(of: nextRecord)
        let normalizedStartDate = min(startDate, defaultAnchor)
        let normalizedEndDate = max(startDate, endDate)

        return PhaseWindow(
            phase: phase,
            startDate: normalizedStartDate,
            endDate: normalizedEndDate
        )
    }

    // MARK: - Fallback

    /// 오늘이 어떤 명시적 record나 gap 안에도 들어가지 않을 때 사용하는 보정 규칙.
    ///
    /// 우선순위는 "완전한 gap > 미래 경계 > 과거 경계 > 오늘 하루" 순서다.
    private func makeFallbackWindow(
        today: Date,
        previousMenstrualRecord: MenstrualRecord?,
        previousOvulationRecord: MenstrualRecord?,
        nextMenstrualRecord: MenstrualRecord?,
        nextOvulationRecord: MenstrualRecord?
    ) -> PhaseWindow {
        if let follicularWindow = makeFollicularWindow(
            after: previousMenstrualRecord,
            before: nextOvulationRecord,
            today: today
        ) {
            return follicularWindow
        }

        if let lutealWindow = makeLutealWindow(
            after: previousOvulationRecord,
            before: nextMenstrualRecord,
            today: today
        ) {
            return lutealWindow
        }

        if let nextMenstrualRecord {
            let endDate = calendar.date(byAdding: .day, value: -1, to: startDay(of: nextMenstrualRecord)) ?? today
            return PhaseWindow(
                phase: .luteal,
                startDate: today,
                endDate: max(today, endDate)
            )
        }

        if let nextOvulationRecord {
            let endDate = calendar.date(byAdding: .day, value: -1, to: startDay(of: nextOvulationRecord)) ?? today
            return PhaseWindow(
                phase: .follicular,
                startDate: today,
                endDate: max(today, endDate)
            )
        }

        if let previousOvulationRecord {
            let startDate = calendar.date(byAdding: .day, value: 1, to: endDay(of: previousOvulationRecord)) ?? today
            return PhaseWindow(
                phase: .luteal,
                startDate: min(startDate, today),
                endDate: today
            )
        }

        if let previousMenstrualRecord {
            let startDate = calendar.date(byAdding: .day, value: 1, to: endDay(of: previousMenstrualRecord)) ?? today
            return PhaseWindow(
                phase: .follicular,
                startDate: min(startDate, today),
                endDate: today
            )
        }

        return PhaseWindow(
            phase: .luteal,
            startDate: today,
            endDate: today
        )
    }

    // MARK: - Date Helpers

    private func startDay(of record: MenstrualRecord) -> Date {
        calendar.startOfDay(for: record.startDate)
    }

    private func endDay(of record: MenstrualRecord) -> Date {
        calendar.startOfDay(for: record.endDate ?? record.startDate)
    }

    private func contains(_ record: MenstrualRecord, day: Date) -> Bool {
        let startDate = startDay(of: record)
        let endDate = endDay(of: record)
        return startDate <= day && day <= endDate
    }
}
