//
//  MithmTests.swift
//  MithmTests
//
//  Created by YunhakLee on 11/18/25.
//

import Foundation
import Testing
@testable import Mithm

struct MenstrualPredictionEngineTests {
    private let calendar = TestCalendar.make()
    private let engine = MenstrualPredictionEngine()

    @Test("유효한 기록이 없으면 예측 없이 insufficient를 반환한다")
    func noValidRecordsReturnsInsufficient() {
        let records = [
            makeRecord(type: .ovulationPrediction, start: "2026-01-10", end: "2026-01-10"),
            makeRecord(type: .menstrualRecord, start: "2026-01-20", end: nil),
            makeRecord(type: .menstrualRecord, start: "2026-02-01", end: "2026-01-30")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.menstrualPredictions.isEmpty)
        #expect(result.predictedCycleLength == nil)
        #expect(result.predictedPeriodLength == nil)
        #expect(result.confidence == .insufficient)
        #expect(result.usedRecordCount == 0)
        #expect(result.detectedShift == false)
        #expect(result.usedDefaultRule == false)
    }

    @Test("유효 기록이 1개면 예측을 생성하지 않는다")
    func oneValidRecordReturnsNoMenstrualPrediction() {
        let records = [
            makeRecord(type: .menstrualRecord, start: "2026-01-10", end: "2026-01-14")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.menstrualPredictions.isEmpty)
        #expect(result.predictedCycleLength == nil)
        #expect(result.predictedPeriodLength == nil)
        #expect(result.confidence == .insufficient)
        #expect(result.usedRecordCount == 1)
    }

    @Test("유효 기록이 2개면 단일 cycle로 다음 3개 월경을 예측한다")
    func twoValidRecordsPredictThreeCycles() {
        let records = [
            makeRecord(type: .menstrualRecord, start: "2026-01-01", end: "2026-01-05"),
            makeRecord(type: .menstrualRecord, start: "2026-01-30", end: "2026-02-03")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.predictedCycleLength == 29)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .low)
        #expect(result.usedRecordCount == 2)
        #expect(result.menstrualPredictions.count == 3)

        // 1번째 예측: 01-30 + 29 = 02-28
        #expect(result.menstrualPredictions[0].type == .menstrualPrediction)
        #expect(Self.dayString(result.menstrualPredictions[0].startDate, calendar: calendar) == "2026-02-28")
        #expect(Self.dayString(result.menstrualPredictions[0].endDate, calendar: calendar) == "2026-03-04")

        // 2번째 예측: 02-28 + 29 = 03-29
        #expect(Self.dayString(result.menstrualPredictions[1].startDate, calendar: calendar) == "2026-03-29")
        #expect(Self.dayString(result.menstrualPredictions[1].endDate, calendar: calendar) == "2026-04-02")

        // 3번째 예측: 03-29 + 29 = 04-27
        #expect(Self.dayString(result.menstrualPredictions[2].startDate, calendar: calendar) == "2026-04-27")
        #expect(Self.dayString(result.menstrualPredictions[2].endDate, calendar: calendar) == "2026-05-01")
    }

    @Test("예측 타입과 잘못된 길이 기록은 학습 데이터에서 제외한다")
    func ignoresPredictionsAndInvalidDurations() {
        let records = [
            makeRecord(type: .menstrualRecord, start: "2026-01-01", end: "2026-01-05"),
            makeRecord(type: .menstrualPrediction, start: "2026-01-28", end: "2026-02-01"),
            makeRecord(type: .menstrualRecord, start: "2026-01-30", end: "2026-02-20"),
            makeRecord(type: .menstrualRecord, start: "2026-02-01", end: "2026-02-05"),
            makeRecord(type: .menstrualRecord, start: "2026-03-01", end: "2026-03-05")
        ]

        let actualRecords = MenstrualPredictionEngine.extractActualRecords(from: records)
        let validRecords = engine.validateRecords(actualRecords, calendar: calendar)
        let cycleSamples = engine.makeCycleSamples(from: validRecords, calendar: calendar)

        #expect(actualRecords.count == 4)
        #expect(validRecords.count == 3)
        #expect(cycleSamples.map(\.cycleLength) == [31, 28])
    }

    @Test("최근 주기 변화가 크면 shift를 감지하고 confidence를 낮춘다")
    func detectsShiftForRecentPatternChange() {
        let records = [
            makeRecord(type: .menstrualRecord, start: "2025-01-01", end: "2025-01-05"),
            makeRecord(type: .menstrualRecord, start: "2025-01-29", end: "2025-02-02"),
            makeRecord(type: .menstrualRecord, start: "2025-02-26", end: "2025-03-02"),
            makeRecord(type: .menstrualRecord, start: "2025-03-26", end: "2025-03-30"),
            makeRecord(type: .menstrualRecord, start: "2025-04-27", end: "2025-05-01"),
            makeRecord(type: .menstrualRecord, start: "2025-05-29", end: "2025-06-02"),
            makeRecord(type: .menstrualRecord, start: "2025-07-04", end: "2025-07-08")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.detectedShift == true)
        #expect(result.predictedCycleLength == 32)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .low)
        #expect(result.menstrualPredictions.count == 3)
        #expect(Self.dayString(result.menstrualPredictions[0].startDate, calendar: calendar) == "2025-08-05")
    }

    @Test("규칙적인 최근 6개 주기에서는 high confidence와 3개 예측을 반환한다")
    func stableRegularCyclesReturnHighConfidence() {
        let records = [
            makeRecord(type: .menstrualRecord, start: "2025-01-01", end: "2025-01-05"),
            makeRecord(type: .menstrualRecord, start: "2025-01-29", end: "2025-02-02"),
            makeRecord(type: .menstrualRecord, start: "2025-02-26", end: "2025-03-02"),
            makeRecord(type: .menstrualRecord, start: "2025-03-26", end: "2025-03-30"),
            makeRecord(type: .menstrualRecord, start: "2025-04-23", end: "2025-04-27"),
            makeRecord(type: .menstrualRecord, start: "2025-05-21", end: "2025-05-25"),
            makeRecord(type: .menstrualRecord, start: "2025-06-18", end: "2025-06-22")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.detectedShift == false)
        #expect(result.predictedCycleLength == 28)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .high)
        #expect(result.usedRecordCount == 7)
        #expect(result.menstrualPredictions.count == 3)

        // 1번째: 06-18 + 28 = 07-16
        #expect(Self.dayString(result.menstrualPredictions[0].startDate, calendar: calendar) == "2025-07-16")
        #expect(Self.dayString(result.menstrualPredictions[0].endDate, calendar: calendar) == "2025-07-20")
        // 2번째: 07-16 + 28 = 08-13
        #expect(Self.dayString(result.menstrualPredictions[1].startDate, calendar: calendar) == "2025-08-13")
        #expect(Self.dayString(result.menstrualPredictions[1].endDate, calendar: calendar) == "2025-08-17")
        // 3번째: 08-13 + 28 = 09-10
        #expect(Self.dayString(result.menstrualPredictions[2].startDate, calendar: calendar) == "2025-09-10")
        #expect(Self.dayString(result.menstrualPredictions[2].endDate, calendar: calendar) == "2025-09-14")
    }

    @Test("최근 6개 주기의 range가 4에서 7 사이면 moderate로 분류한다")
    func classifiesModerateVariabilityFromRecentRange() {
        let variability = engine.classifyVariability(from: [28, 29, 31, 32, 30, 35])
        #expect(variability == .moderate)
    }

    @Test("최근 6개 주기의 range가 8 이상이면 irregular로 분류한다")
    func classifiesIrregularVariabilityFromRecentRange() {
        let variability = engine.classifyVariability(from: [26, 28, 29, 33, 34, 37])
        #expect(variability == .irregular)
    }

    @Test("최근 패턴 차이가 4일 미만이면 shift로 보지 않는다")
    func doesNotDetectShiftWhenDifferenceIsBelowThreshold() {
        let cycles = [28, 29, 29, 30, 31, 31]
        let detected = engine.detectShift(from: cycles)
        #expect(detected == false)
    }

    @Test("clean cycle은 중앙값 기준 편차에 따라 가중치를 낮춘다")
    func cleanCyclesAssignWeightFactorsByDeviation() {
        // median([27,28,29,36,45]) = 29, deviations: 2,1,0,7,16
        let samples = [
            CycleSample(startDate: Self.date("2025-01-29", calendar: calendar), cycleLength: 27, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-02-26", calendar: calendar), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-03-26", calendar: calendar), cycleLength: 29, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-04-23", calendar: calendar), cycleLength: 36, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-05-21", calendar: calendar), cycleLength: 45, weightFactor: 1.0)
        ]

        let cleaned = engine.cleanCycleSamples(samples)

        #expect(cleaned.map(\.cycleLength) == [27, 28, 29, 36, 45])
        // deviation ≤5 → 1.0, 6…9 → 0.5, ≥10 → 0.2
        #expect(cleaned.map(\.weightFactor) == [1.0, 1.0, 1.0, 0.5, 0.2])
    }

    @Test("15일 미만 또는 90일 초과 cycle은 학습용 cycle에서 제외한다")
    func excludesOutOfRangeCycleLengths() {
        let records = [
            makeRecord(type: .menstrualRecord, start: "2025-01-01", end: "2025-01-05"),
            makeRecord(type: .menstrualRecord, start: "2025-01-10", end: "2025-01-14"),
            makeRecord(type: .menstrualRecord, start: "2025-04-20", end: "2025-04-24"),
            makeRecord(type: .menstrualRecord, start: "2025-05-19", end: "2025-05-23")
        ]

        let actualRecords = MenstrualPredictionEngine.extractActualRecords(from: records)
        let validRecords = engine.validateRecords(actualRecords, calendar: calendar)
        let cycleSamples = engine.makeCycleSamples(from: validRecords, calendar: calendar)

        #expect(validRecords.count == 4)
        #expect(cycleSamples.map(\.cycleLength) == [29])
    }

    @Test("4개 기록에서는 축소 adaptive 모델로 다음 3개 월경을 예측한다")
    func fourRecordsUseReducedAdaptivePrediction() {
        // cycles: [28, 29, 30], variability=regular(range=2), alpha=0.35
        // EWMA: 28 → 28.35 → 28.93, longTerm median=29
        // pred = 0.70×28.93 + 0.30×29.0 = 28.95 → round = 29
        let records = [
            makeRecord(type: .menstrualRecord, start: "2025-01-01", end: "2025-01-05"),
            makeRecord(type: .menstrualRecord, start: "2025-01-29", end: "2025-02-02"),
            makeRecord(type: .menstrualRecord, start: "2025-02-27", end: "2025-03-03"),
            makeRecord(type: .menstrualRecord, start: "2025-03-29", end: "2025-04-02")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.predictedCycleLength == 29)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .medium)
        #expect(result.detectedShift == false)
        #expect(result.menstrualPredictions.count == 3)
        #expect(Self.dayString(result.menstrualPredictions[0].startDate, calendar: calendar) == "2025-04-27")
        #expect(Self.dayString(result.menstrualPredictions[0].endDate, calendar: calendar) == "2025-05-01")
    }

    @Test("period 예측은 6개 이상 데이터에서 variability에 따라 short-term과 long-term을 혼합한다")
    func periodPredictionUsesWeightedMixWhenEnoughHistoryExists() {
        let periods = [
            PeriodSample(startDate: Self.date("2025-01-01", calendar: calendar), periodLength: 4),
            PeriodSample(startDate: Self.date("2025-01-29", calendar: calendar), periodLength: 4),
            PeriodSample(startDate: Self.date("2025-02-26", calendar: calendar), periodLength: 5),
            PeriodSample(startDate: Self.date("2025-03-26", calendar: calendar), periodLength: 5),
            PeriodSample(startDate: Self.date("2025-04-23", calendar: calendar), periodLength: 6),
            PeriodSample(startDate: Self.date("2025-05-21", calendar: calendar), periodLength: 6)
        ]

        let regular = engine.predictPeriodLength(from: periods, variability: .regular)
        let irregular = engine.predictPeriodLength(from: periods, variability: .irregular)

        #expect(regular == 5)
        #expect(irregular == 6)
    }

    @Test("buildMenstrualPredictions는 지정된 개수만큼 연쇄 예측을 생성한다")
    func buildMenstrualPredictionsGeneratesConsecutiveRecords() {
        let anchor = Self.date("2026-04-01", calendar: calendar)

        let predictions = MenstrualPredictionEngine.buildMenstrualPredictions(
            from: anchor,
            cycleLength: 28,
            periodLength: 5,
            count: 3,
            calendar: calendar
        )

        #expect(predictions.count == 3)
        #expect(predictions.allSatisfy { $0.type == .menstrualPrediction })

        // 1번째: 04-01 + 28 = 04-29
        #expect(Self.dayString(predictions[0].startDate, calendar: calendar) == "2026-04-29")
        #expect(Self.dayString(predictions[0].endDate, calendar: calendar) == "2026-05-03")
        // 2번째: 04-29 + 28 = 05-27
        #expect(Self.dayString(predictions[1].startDate, calendar: calendar) == "2026-05-27")
        #expect(Self.dayString(predictions[1].endDate, calendar: calendar) == "2026-05-31")
        // 3번째: 05-27 + 28 = 06-24
        #expect(Self.dayString(predictions[2].startDate, calendar: calendar) == "2026-06-24")
        #expect(Self.dayString(predictions[2].endDate, calendar: calendar) == "2026-06-28")
    }

    @Test("유효 기록 3개면 cycle 2개의 중앙값으로 예측한다")
    func threeRecordsUseCycleMedian() {
        // cycles: [28, 30] → median = 29
        let records = [
            makeRecord(type: .menstrualRecord, start: "2025-01-01", end: "2025-01-05"),
            makeRecord(type: .menstrualRecord, start: "2025-01-29", end: "2025-02-02"),
            makeRecord(type: .menstrualRecord, start: "2025-02-28", end: "2025-03-04")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.predictedCycleLength == 29)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .low)
        #expect(result.usedRecordCount == 3)
        #expect(result.menstrualPredictions.count == 3)
        #expect(Self.dayString(result.menstrualPredictions[0].startDate, calendar: calendar) == "2025-03-29")
    }

    @Test("clean cycle이 3개 미만이면 가중치 조정 없이 그대로 반환한다")
    func cleanCyclesUnderThreeReturnUnchanged() {
        let samples = [
            CycleSample(startDate: Self.date("2025-01-29", calendar: calendar), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-02-26", calendar: calendar), cycleLength: 50, weightFactor: 1.0)
        ]

        let cleaned = engine.cleanCycleSamples(samples)

        #expect(cleaned.count == 2)
        #expect(cleaned.map(\.weightFactor) == [1.0, 1.0])
    }

    @Test("moderate 변동성에서 full adaptive 예측을 수행한다")
    func moderateVariabilityFullAdaptive() {
        // cycles: [28, 31, 29, 32, 28, 31] → range=4 → moderate
        let records = [
            makeRecord(type: .menstrualRecord, start: "2025-01-01", end: "2025-01-05"),
            makeRecord(type: .menstrualRecord, start: "2025-01-29", end: "2025-02-02"),
            makeRecord(type: .menstrualRecord, start: "2025-03-01", end: "2025-03-05"),
            makeRecord(type: .menstrualRecord, start: "2025-03-30", end: "2025-04-03"),
            makeRecord(type: .menstrualRecord, start: "2025-05-01", end: "2025-05-05"),
            makeRecord(type: .menstrualRecord, start: "2025-05-29", end: "2025-06-02"),
            makeRecord(type: .menstrualRecord, start: "2025-06-29", end: "2025-07-03")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.confidence == .medium)
        #expect(result.detectedShift == false)
        #expect(result.predictedCycleLength != nil)
        #expect(result.menstrualPredictions.count == 3)
    }

    @Test("빈 period 배열에서는 nil을 반환한다")
    func emptyPeriodsReturnNil() {
        let result = engine.predictPeriodLength(from: [], variability: .regular)
        #expect(result == nil)
    }

    @Test("6개 이상 clean cycle + regular + shift가 있으면 confidence는 medium이다")
    func highCycleCountWithShiftReturnsMedium() {
        let confidence = engine.determineConfidence(
            cleanCycleCount: 8,
            variability: .regular,
            shift: true
        )
        #expect(confidence == .medium)
    }

    @Test("6개 이상 clean cycle + moderate + shift 없으면 confidence는 medium이다")
    func highCycleCountModerateReturnsMedium() {
        let confidence = engine.determineConfidence(
            cleanCycleCount: 7,
            variability: .moderate,
            shift: false
        )
        #expect(confidence == .medium)
    }

    @Test("range가 3 이하이면 regular로 분류한다")
    func classifiesRegularVariability() {
        let variability = engine.classifyVariability(from: [28, 29, 28, 30, 29, 28])
        #expect(variability == .regular)
    }

    @Test("cycle이 6개 미만이면 shift를 감지하지 않는다")
    func doesNotDetectShiftWithFewCycles() {
        let detected = engine.detectShift(from: [28, 35, 35])
        #expect(detected == false)
    }

    @Test("3개에서 5개의 clean cycle이고 irregular이면 confidence는 low를 반환한다")
    func irregularCyclesReturnLowConfidence() {
        let confidence = engine.determineConfidence(
            cleanCycleCount: 4,
            variability: .irregular,
            shift: false
        )

        #expect(confidence == .low)
    }

    @Test("3개에서 5개의 clean cycle이고 regular면 confidence는 medium을 반환한다")
    func smallButStableCycleHistoryReturnsMediumConfidence() {
        let confidence = engine.determineConfidence(
            cleanCycleCount: 4,
            variability: .regular,
            shift: false
        )

        #expect(confidence == .medium)
    }

    @Test("Config로 predictionCount를 변경하면 해당 개수만큼 예측한다")
    func customPredictionCountConfig() {
        let customEngine = MenstrualPredictionEngine(config: {
            var c = MenstrualPredictionEngine.Config.default
            return MenstrualPredictionEngine.Config(
                validPeriodRange: c.validPeriodRange,
                validCycleRange: c.validCycleRange,
                outlierNormalThreshold: c.outlierNormalThreshold,
                outlierMildThreshold: c.outlierMildThreshold,
                outlierMildWeight: c.outlierMildWeight,
                outlierSevereWeight: c.outlierSevereWeight,
                variabilityRegularMaxRange: c.variabilityRegularMaxRange,
                variabilityModerateMaxRange: c.variabilityModerateMaxRange,
                ewmaAlphaRegular: c.ewmaAlphaRegular,
                ewmaAlphaModerate: c.ewmaAlphaModerate,
                ewmaAlphaIrregular: c.ewmaAlphaIrregular,
                cycleWeightRegular: c.cycleWeightRegular,
                cycleWeightModerate: c.cycleWeightModerate,
                cycleWeightIrregular: c.cycleWeightIrregular,
                cycleWeightShift: c.cycleWeightShift,
                cycleWeightReduced: c.cycleWeightReduced,
                periodWeightStable: c.periodWeightStable,
                periodWeightIrregular: c.periodWeightIrregular,
                shiftThreshold: c.shiftThreshold,
                predictionCount: 5
            )
        }())

        let records = [
            makeRecord(type: .menstrualRecord, start: "2025-01-01", end: "2025-01-05"),
            makeRecord(type: .menstrualRecord, start: "2025-01-29", end: "2025-02-02")
        ]

        let result = customEngine.predict(from: records, calendar: calendar)
        #expect(result.menstrualPredictions.count == 5)
    }

    private func makeRecord(type: MenstrualRecordType, start: String, end: String?) -> MenstrualRecord {
        MenstrualRecord(
            type: type,
            startDate: Self.date(start, calendar: calendar),
            endDate: end.map { Self.date($0, calendar: calendar) }
        )
    }

    private static func date(_ value: String, calendar: Calendar) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }

    private static func dayString(_ date: Date?, calendar: Calendar) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private enum TestCalendar {
    static func make() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}
