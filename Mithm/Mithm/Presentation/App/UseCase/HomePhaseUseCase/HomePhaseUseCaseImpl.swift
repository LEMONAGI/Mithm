//
//  HomePhaseUseCaseImpl.swift
//  Mithm
//
//  Created by Codex on 8/13/25.
//

import Foundation

/// 홈 화면의 현재 phase를 "사용자 직접 시작 월경 우선" 규칙으로 계산한다.
///
/// 진행 중이거나 오늘 종료한 월경 표시 기간이 있는 경우에만 월경기로 진입하고,
/// 그렇지 않으면 다음 사이클의 예측 데이터는 현재 phase 계산에서 제외한다.
/// 이후 남아 있는 record로 배란기, 난포기, 황체기를 계산한다.
///
/// 판정 순서는 다음과 같다.
/// 1. 표시용 월경 기간(AppStorage)
/// 2. 다음 사이클 시작 경계 이후의 예측 record 제외
/// 3. 오늘이 포함된 배란기 record
/// 4. 이전 월경기와 다음 배란기 사이 gap이면 난포기
/// 5. 이전 배란기와 다음 월경기 사이 gap이면 황체기
/// 6. 어떤 구간에도 속하지 않으면 기존 황체기 시작점을 유지하며 황체기
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
        menstrualDisplayWindow: MenstrualDisplayWindow?,
        today: Date = Date()
    ) -> PhaseWindow {
        let today = calendar.startOfDay(for: today)

        // 1) 표시용 월경 기간이 있으면 가장 우선한다.
        if let activeMenstrualWindow = makeActiveMenstrualWindow(
            menstrualDisplayWindow: menstrualDisplayWindow,
            predictedPeriodLength: menstrualOverview.prediction?.predictedPeriodLength,
            today: today
        ) {
            return activeMenstrualWindow
        }

        // 2) 표시할 월경 기간이 없는 경우,
        // 다음 사이클 시작 경계 이후의 예측 record는 현재 phase 계산에서 제외한다.
        let scopedRecords = makeScopedRecords(from: menstrualOverview.allRecords)
        let menstrualRecords = scopedRecords.filter {
            $0.type == .menstrualRecord
                || $0.type == .menstrualPrediction
        }
        let ovulationWindowRecords = scopedRecords.filter {
            $0.type == .ovulationFertileWindowEstimated
                || $0.type == .ovulationFertileWindowPrediction
        }

        // 3) 오늘이 배란기 record 안에 포함되면 현재 phase는 배란기다.
        if let currentOvulationRecord = ovulationWindowRecords
            .first(where: { contains($0, day: today) }) {
            return PhaseWindow(
                phase: .ovulation,
                startDate: startDay(of: currentOvulationRecord),
                endDate: endDay(of: currentOvulationRecord)
            )
        }

        // 4) scopedRecords에서 난포기/황체기 계산에 필요한 경계 record를 찾는다.
        let previousMenstrualRecord = menstrualRecords
            .last(where: { endDay(of: $0) < today })
        let nextMenstrualRecord = menstrualRecords
            .first(where: { startDay(of: $0) > today })
        let previousOvulationRecord = ovulationWindowRecords
            .last(where: { endDay(of: $0) < today })
        let nextOvulationRecord = ovulationWindowRecords
            .first(where: { startDay(of: $0) > today })

        // 황체기 종료 경계 탐색: 실제 월경 기록이 없으면 예측도 포함한다.
        // 예측 월경을 시작된 것으로 간주하지 않는 scoping 규칙과 독립적으로 동작한다.
        let nextMenstrualOrPrediction: MenstrualRecord?
        if let nextMenstrualRecord {
            nextMenstrualOrPrediction = nextMenstrualRecord
        } else {
            nextMenstrualOrPrediction = menstrualOverview.allRecords
                .filter { $0.type == .menstrualRecord || $0.type == .menstrualPrediction }
                .first { startDay(of: $0) > today }
        }

        // 5) 이전 월경과 다음 배란 사이 gap 안에 오늘이 있으면 난포기다.
        if let follicularWindow = makeFollicularWindow(
            after: previousMenstrualRecord,
            before: nextOvulationRecord
        ), follicularWindow.startDate <= today, today <= follicularWindow.endDate {
            return follicularWindow
        }

        // 6) 이전 배란과 다음 월경 사이 gap 안에 오늘이 있으면 황체기다.
        if let lutealWindow = makeLutealWindow(
            after: previousOvulationRecord,
            before: nextMenstrualOrPrediction
        ), lutealWindow.startDate <= today, today <= lutealWindow.endDate {
            return lutealWindow
        }

        // 7) 어떤 구간에도 포함되지 않으면 황체기를 유지한다.
        // 이전 배란기가 있으면 그 다음 날부터 오늘까지 황체기를 연장한다.
        if let previousOvulationRecord {
            let lutealStart = calendar.date(
                byAdding: .day,
                value: 1,
                to: endDay(of: previousOvulationRecord)
            ) ?? today

            return PhaseWindow(
                phase: .luteal,
                startDate: lutealStart,
                endDate: today
            )
        }

        return PhaseWindow(
            phase: .luteal,
            startDate: today,
            endDate: today
        )
    }

    // MARK: - Active Menstrual

    func execute(
        menstrualOverview: MenstrualOverview,
        activeMenstrualStartDate: Date?,
        today: Date = Date()
    ) -> PhaseWindow {
        execute(
            menstrualOverview: menstrualOverview,
            menstrualDisplayWindow: activeMenstrualStartDate.map {
                MenstrualDisplayWindow(startDate: $0, endDate: nil)
            },
            today: today
        )
    }

    /// 홈에 표시할 월경 기간이 있으면 월경기 구간을 만든다.
    /// 진행 중 월경은 예측 기간을 사용하고, 당일 종료 월경은 기록된 종료일까지 표시한다.
    private func makeActiveMenstrualWindow(
        menstrualDisplayWindow: MenstrualDisplayWindow?,
        predictedPeriodLength: Int?,
        today: Date
    ) -> PhaseWindow? {
        guard let menstrualDisplayWindow else { return nil }

        let activeStartDate = calendar.startOfDay(for: menstrualDisplayWindow.startDate)
        if let endDate = menstrualDisplayWindow.endDate {
            return PhaseWindow(
                phase: .menstrual,
                startDate: activeStartDate,
                endDate: calendar.startOfDay(for: endDate)
            )
        }

        let resolvedPeriodLength = predictedPeriodLength ?? defaultPeriodLength
        let predictedEndDate = calendar.date(
            byAdding: .day,
            value: max(resolvedPeriodLength - 1, 0),
            to: activeStartDate
        ) ?? activeStartDate

        return PhaseWindow(
            phase: .menstrual,
            startDate: activeStartDate,
            endDate: max(predictedEndDate, today)
        )
    }

    // MARK: - Scoped Records

    /// 사용자가 월경 시작을 직접 기록하지 않은 경우,
    /// 다음 사이클 시작 경계 이후의 예측 record는 현재 phase 계산에서 제외한다.
    private func makeScopedRecords(from allRecords: [MenstrualRecord]) -> [MenstrualRecord] {
        let nextCycleBoundary = allRecords
            .filter { $0.type == .menstrualPrediction }
            .map { startDay(of: $0) }
            .min()

        guard let nextCycleBoundary else { return allRecords }

        return allRecords.filter { record in
            switch record.type {
            case .menstrualPrediction, .ovulationPrediction, .ovulationFertileWindowPrediction:
                return startDay(of: record) < nextCycleBoundary
            case .menstrualRecord, .ovulationEstimated, .ovulationFertileWindowEstimated:
                return true
            }
        }
    }

    // MARK: - Gap Window

    /// 난포기는 "이전 월경기 종료 다음 날 ~ 다음 배란기 시작 전날" 구간이다.
    private func makeFollicularWindow(
        after previousMenstrualRecord: MenstrualRecord?,
        before nextOvulationRecord: MenstrualRecord?
    ) -> PhaseWindow? {
        makeGapWindow(
            phase: .follicular,
            after: previousMenstrualRecord,
            before: nextOvulationRecord
        )
    }

    /// 황체기는 "이전 배란기 종료 다음 날 ~ 다음 월경기 시작 전날" 구간이다.
    private func makeLutealWindow(
        after previousOvulationRecord: MenstrualRecord?,
        before nextMenstrualRecord: MenstrualRecord?
    ) -> PhaseWindow? {
        makeGapWindow(
            phase: .luteal,
            after: previousOvulationRecord,
            before: nextMenstrualRecord
        )
    }

    /// 두 record 사이의 빈 구간을 phase window로 변환한다.
    ///
    /// `defaultAnchor`는 fallback 시점(today)과의 정합성을 맞추기 위한 기준값이다.
    private func makeGapWindow(
        phase: PhaseType,
        after previousRecord: MenstrualRecord?,
        before nextRecord: MenstrualRecord?
    ) -> PhaseWindow? {
        guard let previousRecord, let nextRecord else { return nil }

        let startDate = calendar.date(byAdding: .day, value: 1, to: endDay(of: previousRecord)) ?? endDay(of: previousRecord)
        let endDate = calendar.date(byAdding: .day, value: -1, to: startDay(of: nextRecord)) ?? startDay(of: nextRecord)
        let normalizedEndDate = max(startDate, endDate)

        return PhaseWindow(
            phase: phase,
            startDate: startDate,
            endDate: normalizedEndDate
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
