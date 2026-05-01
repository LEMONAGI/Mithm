//
//  OpenPeriodAutoCloser.swift
//  Mithm
//
//  Created by YunhakLee on 3/13/26.
//

import Foundation

/// 열려 있는 월경 기록(endDate == nil)이 충분한 시간이 지났을 때 자동 종료 여부를 판별하고,
/// 종료된 MenstrualRecord를 반환하는 헬퍼.
///
/// 자동 종료 조건:
/// 1. 예측 엔진에서 산출한 월경 기간(predictedPeriodLength)으로 예상 종료일을 계산한다.
/// 2. 오늘이 예상 종료일 + 유예기간(gracePeriodDays)을 지난 경우 자동 종료한다.
/// 3. 종료 날짜는 예상 종료일로 설정한다.
struct OpenPeriodAutoCloser {

    struct Config {
        /// 예상 종료일 이후 자동 종료까지의 유예 기간 (일)
        let gracePeriodDays: Int

        static let `default` = Config(gracePeriodDays: 2)
    }

    private let config: Config

    init(config: Config = .default) {
        self.config = config
    }

    /// 열려 있는 월경 기록의 자동 종료를 시도한다.
    ///
    /// - Parameters:
    ///   - openRecord: endDate가 nil인 월경 기록 (진행 중인 월경)
    ///   - predictedPeriodLength: 예측 엔진 등에서 산출한 월경 기간 (일수)
    ///   - referenceDate: 현재 날짜 기준 (기본값: 오늘)
    ///   - calendar: 날짜 계산에 사용할 Calendar
    /// - Returns: 자동 종료 조건 충족 시 endDate가 채워진 MenstrualRecord, 미충족 시 nil
    func tryAutoClose(
        openRecord: MenstrualRecord,
        predictedPeriodLength: Int,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> MenstrualRecord? {
        guard openRecord.endDate == nil else { return nil }

        let startDay = calendar.startOfDay(for: openRecord.startDate)

        guard let expectedEndDate = calendar.date(
            byAdding: .day,
            value: predictedPeriodLength - 1,
            to: startDay
        ) else {
            return nil
        }

        guard let deadline = calendar.date(
            byAdding: .day,
            value: config.gracePeriodDays,
            to: expectedEndDate
        ) else {
            return nil
        }

        let today = calendar.startOfDay(for: referenceDate)

        guard today > deadline else { return nil }

        return MenstrualRecord(
            type: openRecord.type,
            startDate: openRecord.startDate,
            endDate: expectedEndDate
        )
    }
}

struct CurrentMenstrualStatusResolver {

    private let gracePeriodDays: Int
    private let defaultPeriodLength: Int

    init(
        gracePeriodDays: Int = OpenPeriodAutoCloser.Config.default.gracePeriodDays,
        defaultPeriodLength: Int = MenstrualPredictionEngine.Config.defaultPeriodLength
    ) {
        self.gracePeriodDays = gracePeriodDays
        self.defaultPeriodLength = defaultPeriodLength
    }

    func resolve(
        actualRecords: [MenstrualRecord],
        currentEpisode: CurrentMenstrualEpisode?,
        predictedPeriodLength: Int?,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> CurrentMenstrualStatus {
        let today = calendar.startOfDay(for: today)
        let latestHealthRecord = actualRecords
            .filter { $0.type == .menstrualRecord }
            .sorted {
                if $0.startDate == $1.startDate {
                    return ($0.endDate ?? $0.startDate) < ($1.endDate ?? $1.startDate)
                }
                return $0.startDate < $1.startDate
            }
            .last

        let latestStartDate = latestStartDate(
            latestHealthRecord: latestHealthRecord,
            currentEpisode: currentEpisode,
            calendar: calendar
        )

        guard let latestStartDate else {
            return .inactive()
        }

        let startDate = calendar.startOfDay(for: latestStartDate)
        let resolvedPeriodLength = predictedPeriodLength ?? defaultPeriodLength
        let expectedEndDate = calendar.date(
            byAdding: .day,
            value: max(resolvedPeriodLength - 1, 0),
            to: startDate
        ) ?? startDate
        let deadline = calendar.date(
            byAdding: .day,
            value: gracePeriodDays,
            to: expectedEndDate
        ) ?? expectedEndDate

        if isClosedEpisode(currentEpisode, for: startDate, calendar: calendar) {
            return .inactive(
                latestStartDate: startDate,
                expectedEndDate: expectedEndDate
            )
        }

        let todayHasHealthRecord = latestHealthRecord.map {
            contains($0, day: today, calendar: calendar)
        } ?? false
        let hasOpenEpisode = isOpenEpisode(currentEpisode, for: startDate, calendar: calendar)

        if today > deadline {
            if hasOpenEpisode {
                return CurrentMenstrualStatus(
                    isActive: true,
                    activeStartDate: startDate,
                    latestStartDate: startDate,
                    expectedEndDate: expectedEndDate,
                    shouldAutoClose: true
                )
            }

            return .inactive(
                latestStartDate: startDate,
                expectedEndDate: expectedEndDate,
                shouldAutoClose: true
            )
        }

        let isWithinAutoCloseWindow = startDate <= today && today <= deadline

        guard todayHasHealthRecord || isWithinAutoCloseWindow else {
            return .inactive(
                latestStartDate: startDate,
                expectedEndDate: expectedEndDate
            )
        }

        return CurrentMenstrualStatus(
            isActive: true,
            activeStartDate: startDate,
            latestStartDate: startDate,
            expectedEndDate: expectedEndDate,
            shouldAutoClose: false
        )
    }

    private func latestStartDate(
        latestHealthRecord: MenstrualRecord?,
        currentEpisode: CurrentMenstrualEpisode?,
        calendar: Calendar
    ) -> Date? {
        let healthStartDate = latestHealthRecord.map { calendar.startOfDay(for: $0.startDate) }
        let episodeStartDate = currentEpisode.map { calendar.startOfDay(for: $0.startDate) }

        switch (healthStartDate, episodeStartDate) {
        case let (health?, episode?):
            return max(health, episode)
        case let (health?, nil):
            return health
        case let (nil, episode?):
            return episode
        case (nil, nil):
            return nil
        }
    }

    private func isClosedEpisode(
        _ currentEpisode: CurrentMenstrualEpisode?,
        for startDate: Date,
        calendar: Calendar
    ) -> Bool {
        guard let currentEpisode, currentEpisode.isClosed else {
            return false
        }
        return calendar.isDate(currentEpisode.startDate, inSameDayAs: startDate)
    }

    private func isOpenEpisode(
        _ currentEpisode: CurrentMenstrualEpisode?,
        for startDate: Date,
        calendar: Calendar
    ) -> Bool {
        guard let currentEpisode, currentEpisode.closedReason == nil else {
            return false
        }
        return calendar.isDate(currentEpisode.startDate, inSameDayAs: startDate)
    }

    private func contains(
        _ record: MenstrualRecord,
        day: Date,
        calendar: Calendar
    ) -> Bool {
        let startDate = calendar.startOfDay(for: record.startDate)
        let endDate = calendar.startOfDay(for: record.endDate ?? record.startDate)
        return startDate <= day && day <= endDate
    }
}
