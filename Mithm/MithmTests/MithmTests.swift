//
//  MithmTests.swift
//  MithmTests
//
//  Created by YunhakLee on 11/18/25.
//

import Foundation
import Testing
@testable import Mithm

// MARK: - 1. 기록 필터링 및 유효성 검증

struct RecordFilteringTests {
    private let calendar = TestCalendar.make()
    private let engine = MenstrualPredictionEngine()

    // MARK: extractActualRecords

    @Test("extractActualRecords — 예측 타입 기록은 제외하고 실제 월경 기록만 추출한다")
    func extractsOnlyActualMenstrualRecords() {
        let records = [
            makeRecord(type: .menstrualRecord, start: "2026-01-01", end: "2026-01-05"),
            makeRecord(type: .menstrualPrediction, start: "2026-01-28", end: "2026-02-01"),
            makeRecord(type: .ovulationPrediction, start: "2026-02-10", end: "2026-02-10"),
            makeRecord(type: .menstrualRecord, start: "2026-02-01", end: "2026-02-05")
        ]

        let actual = MenstrualPredictionEngine.extractActualRecords(from: records)

        #expect(actual.count == 2)
        #expect(actual.allSatisfy { $0.type == .menstrualRecord })
    }

    @Test("extractActualRecords — endDate가 nil인 기록은 제외한다")
    func excludesRecordsWithNilEndDate() {
        let records = [
            makeRecord(type: .menstrualRecord, start: "2026-01-01", end: nil),
            makeRecord(type: .menstrualRecord, start: "2026-01-10", end: "2026-01-14")
        ]

        let actual = MenstrualPredictionEngine.extractActualRecords(from: records)

        #expect(actual.count == 1)
    }

    @Test("extractActualRecords — 결과는 startDate 기준 오름차순으로 정렬된다")
    func sortsRecordsByStartDateAscending() {
        let records = [
            makeRecord(type: .menstrualRecord, start: "2026-03-01", end: "2026-03-05"),
            makeRecord(type: .menstrualRecord, start: "2026-01-01", end: "2026-01-05"),
            makeRecord(type: .menstrualRecord, start: "2026-02-01", end: "2026-02-05")
        ]

        let actual = MenstrualPredictionEngine.extractActualRecords(from: records)

        #expect(actual.count == 3)
        #expect(actual[0].startDate < actual[1].startDate)
        #expect(actual[1].startDate < actual[2].startDate)
    }

    // MARK: validateRecords

    @Test("validateRecords — endDate가 startDate보다 이른 기록은 무효 처리한다")
    func rejectsRecordsWhereEndDateBeforeStartDate() {
        let records = [
            makeRecord(type: .menstrualRecord, start: "2026-02-01", end: "2026-01-30")
        ]

        let actual = MenstrualPredictionEngine.extractActualRecords(from: records)
        let valid = engine.validateRecords(actual, calendar: calendar)

        #expect(valid.isEmpty)
    }

    @Test("validateRecords — period length가 유효 범위(2~8일)를 벗어나면 제외한다")
    func rejectsRecordsWithPeriodLengthOutOfRange() {
        let records = [
            makeRecord(type: .menstrualRecord, start: "2026-01-01", end: "2026-01-05"),  // 5일 → 유효
            makeRecord(type: .menstrualRecord, start: "2026-02-01", end: "2026-02-20")   // 20일 → 무효
        ]

        let actual = MenstrualPredictionEngine.extractActualRecords(from: records)
        let valid = engine.validateRecords(actual, calendar: calendar)

        #expect(valid.count == 1)
    }

    @Test("validateRecords — 빈 배열을 넣으면 빈 배열을 반환한다")
    func emptyInputReturnsEmpty() {
        let valid = engine.validateRecords([], calendar: calendar)
        #expect(valid.isEmpty)
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
}

// MARK: - 2. Cycle / Period 샘플 생성

struct SampleGenerationTests {
    private let calendar = TestCalendar.make()
    private let engine = MenstrualPredictionEngine()

    @Test("makeCycleSamples — 기록이 1개이면 cycle을 생성할 수 없어 빈 배열을 반환한다")
    func singleRecordReturnEmptyCycles() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05")
        ]
        let samples = engine.makeCycleSamples(from: records, calendar: calendar)
        #expect(samples.isEmpty)
    }

    @Test("makeCycleSamples — 유효 범위(20~45일) 밖의 cycle은 제외한다")
    func excludesCycleLengthsOutOfValidRange() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-10", end: "2025-01-14"),  // 9일 → 범위 밖
            makeRecord(start: "2025-04-20", end: "2025-04-24"),  // 100일 → 범위 밖
            makeRecord(start: "2025-05-19", end: "2025-05-23")   // 29일 → 유효
        ]

        let samples = engine.makeCycleSamples(from: records, calendar: calendar)

        #expect(samples.map(\.cycleLength) == [29])
    }

    @Test("makeCycleSamples — 연속 기록의 cycle length를 정확히 계산한다")
    func calculatesCorrectCycleLengths() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),  // 28일
            makeRecord(start: "2025-02-28", end: "2025-03-04")   // 30일
        ]

        let samples = engine.makeCycleSamples(from: records, calendar: calendar)

        #expect(samples.map(\.cycleLength) == [28, 30])
        #expect(samples.allSatisfy { $0.weightFactor == 1.0 })
    }

    @Test("makePeriodSamples — 각 기록의 period length(양끝 포함 일수)를 정확히 계산한다")
    func calculatesPeriodLengthsInclusiveOfBothEnds() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),  // 5일
            makeRecord(start: "2025-02-01", end: "2025-02-01")   // 1일
        ]

        let samples = engine.makePeriodSamples(from: records, calendar: calendar)

        #expect(samples.map(\.periodLength) == [5, 1])
    }

    private func makeRecord(start: String, end: String) -> MenstrualRecord {
        MenstrualRecord(
            type: .menstrualRecord,
            startDate: Self.date(start, calendar: calendar),
            endDate: Self.date(end, calendar: calendar)
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
}

// MARK: - 3. Clean Cycle (이상치 가중치 할당)

struct CleanCycleTests {
    private let calendar = TestCalendar.make()
    private let engine = MenstrualPredictionEngine()

    @Test("cleanCycleSamples — 3개 미만이면 가중치 조정 없이 그대로 반환한다")
    func underThreeSamplesReturnUnchanged() {
        let samples = [
            CycleSample(startDate: Self.date("2025-01-29"), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-02-26"), cycleLength: 50, weightFactor: 1.0)
        ]

        let cleaned = engine.cleanCycleSamples(samples)

        #expect(cleaned.count == 2)
        #expect(cleaned.map(\.weightFactor) == [1.0, 1.0])
    }

    @Test("cleanCycleSamples — 중앙값 대비 편차 ≤4이면 가중치 1.0, 5~8이면 0.35, ≥9이면 0.10을 할당한다")
    func assignsWeightsByDeviationFromMedian() {
        // median([27,28,29,36,45]) = 29, deviations: 2,1,0,7,16
        let samples = [
            CycleSample(startDate: Self.date("2025-01-29"), cycleLength: 27, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-02-26"), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-03-26"), cycleLength: 29, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-04-23"), cycleLength: 36, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-05-21"), cycleLength: 45, weightFactor: 1.0)
        ]

        let cleaned = engine.cleanCycleSamples(samples)

        #expect(cleaned.map(\.cycleLength) == [27, 28, 29, 36, 45])
        #expect(cleaned.map(\.weightFactor) == [1.0, 1.0, 1.0, 0.35, 0.10])
    }

    @Test("cleanCycleSamples — 모든 cycle이 동일하면 전부 가중치 1.0이다")
    func identicalCyclesAllGetWeight1() {
        let samples = (0..<5).map { i in
            CycleSample(startDate: Self.date("2025-0\(i + 1)-01"), cycleLength: 28, weightFactor: 1.0)
        }

        let cleaned = engine.cleanCycleSamples(samples)

        #expect(cleaned.allSatisfy { $0.weightFactor == 1.0 })
    }

    private static func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}

// MARK: - 4. Variability 분류 (severe outlier 제외)

struct VariabilityTests {
    private let engine = MenstrualPredictionEngine()

    @Test("classifyVariability — 최근 6개 range ≤ 4이면 regular로 분류한다")
    func rangeUpTo4IsRegular() {
        let variability = engine.classifyVariability(from: [28, 29, 28, 30, 29, 28])
        #expect(variability == .regular)
    }

    @Test("classifyVariability — 최근 6개 range 5~8이면 moderate로 분류한다")
    func range5To8IsModerate() {
        let variability = engine.classifyVariability(from: [28, 29, 31, 32, 30, 35])
        #expect(variability == .moderate)
    }

    @Test("classifyVariability — 최근 6개 range ≥ 9이면 irregular로 분류한다")
    func range9OrMoreIsIrregular() {
        let variability = engine.classifyVariability(from: [26, 28, 29, 33, 34, 37])
        #expect(variability == .irregular)
    }

    @Test("classifyVariability — 7개 이상이면 마지막 6개만 사용한다")
    func usesOnlyLast6Cycles() {
        // 처음 2개([20, 45])를 포함하면 range=25 → irregular
        // 하지만 마지막 6개([28,29,28,30,29,28])만 사용 → range=2 → regular
        let variability = engine.classifyVariability(from: [20, 45, 28, 29, 28, 30, 29, 28])
        #expect(variability == .regular)
    }

    @Test("variabilityCycleLengths — severe outlier(weightFactor == outlierSevereWeight)는 variability 계산에서 제외한다")
    func excludesSevereOutliersFromVariability() {
        let samples = [
            CycleSample(startDate: Date(), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Date(), cycleLength: 29, weightFactor: 1.0),
            CycleSample(startDate: Date(), cycleLength: 30, weightFactor: 0.5),
            CycleSample(startDate: Date(), cycleLength: 60, weightFactor: 0.10)  // severe
        ]

        let lengths = engine.variabilityCycleLengths(from: samples)

        // severe(0.10)는 제외, 나머지 3개 사용
        #expect(lengths == [28, 29, 30])
    }

    @Test("variabilityCycleLengths — severe 제외 후 2개 미만이면 전체를 fallback으로 사용한다")
    func fallsBackToAllWhenTooFewAfterExclusion() {
        let samples = [
            CycleSample(startDate: Date(), cycleLength: 28, weightFactor: 0.5),
            CycleSample(startDate: Date(), cycleLength: 60, weightFactor: 0.10),
            CycleSample(startDate: Date(), cycleLength: 70, weightFactor: 0.10)
        ]

        let lengths = engine.variabilityCycleLengths(from: samples)

        // non-severe가 1개뿐이므로 전체 fallback
        #expect(lengths == [28, 60, 70])
    }

    @Test("severe outlier 1개가 섞여도 variability는 나머지 기준으로 regular을 유지한다")
    func singleSevereOutlierDoesNotDistortVariability() {
        // cleanCycles에서 severe outlier가 하나 있지만,
        // variabilityCycleLengths에서 제외되므로 regular 유지
        let samples = [
            CycleSample(startDate: Date(), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Date(), cycleLength: 29, weightFactor: 1.0),
            CycleSample(startDate: Date(), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Date(), cycleLength: 29, weightFactor: 1.0),
            CycleSample(startDate: Date(), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Date(), cycleLength: 55, weightFactor: 0.10)  // severe
        ]

        let lengths = engine.variabilityCycleLengths(from: samples)
        let variability = engine.classifyVariability(from: lengths)

        // severe 제외 → [28,29,28,29,28] → range=1 → regular
        #expect(variability == .regular)
    }
}

// MARK: - 5. Shift 감지

struct ShiftDetectionTests {
    private let engine = MenstrualPredictionEngine()

    @Test("detectShift — 6개 미만이면 항상 false를 반환한다")
    func fewerThan6CyclesReturnsFalse() {
        #expect(engine.detectShift(from: [28, 35, 35]) == false)
        #expect(engine.detectShift(from: [28, 28, 35, 35, 35]) == false)
    }

    @Test("detectShift — 최근 3개와 이전 3~6개의 중앙값 차이가 4일 이상이면 shift를 감지한다")
    func detectsShiftWhenRecentMedianDiffers4OrMore() {
        // 이전: [28,28,28] median=28, 최근: [35,35,35] median=35, 차이=7
        let cycles = [28, 28, 28, 35, 35, 35]
        #expect(engine.detectShift(from: cycles) == true)
    }

    @Test("detectShift — 최근 3개와 이전의 중앙값 차이가 4일 미만이면 shift로 보지 않는다")
    func doesNotDetectShiftWhenDifferenceBelowThreshold() {
        let cycles = [28, 29, 29, 30, 31, 31]
        #expect(engine.detectShift(from: cycles) == false)
    }

    @Test("detectShift — 정확히 임계값 경계(차이 4.0)에서 shift를 감지한다")
    func detectsShiftAtExactThreshold() {
        // 이전: [28,28,28] median=28, 최근: [32,32,32] median=32, 차이=4
        let cycles = [28, 28, 28, 32, 32, 32]
        #expect(engine.detectShift(from: cycles) == true)
    }
}

// MARK: - 6. Confidence 결정

struct ConfidenceTests {
    private let engine = MenstrualPredictionEngine()

    @Test("determineConfidence — clean cycle 0개이면 insufficient를 반환한다")
    func zeroCyclesReturnInsufficient() {
        let c = engine.determineConfidence(cleanCycleCount: 0, variability: nil, shift: false)
        #expect(c == .insufficient)
    }

    @Test("determineConfidence — clean cycle 1~2개이면 low를 반환한다")
    func oneTwoCyclesReturnLow() {
        let c1 = engine.determineConfidence(cleanCycleCount: 1, variability: nil, shift: false)
        let c2 = engine.determineConfidence(cleanCycleCount: 2, variability: .regular, shift: false)
        #expect(c1 == .low)
        #expect(c2 == .low)
    }

    @Test("determineConfidence — irregular이면 기록 수에 관계없이 low를 반환한다")
    func irregularAlwaysReturnsLow() {
        let c = engine.determineConfidence(cleanCycleCount: 10, variability: .irregular, shift: false)
        #expect(c == .low)
    }

    @Test("determineConfidence — 3~5개 + regular/moderate이면 medium을 반환한다")
    func mediumCycleCountRegularReturnsMedium() {
        let c1 = engine.determineConfidence(cleanCycleCount: 4, variability: .regular, shift: false)
        let c2 = engine.determineConfidence(cleanCycleCount: 5, variability: .moderate, shift: false)
        #expect(c1 == .medium)
        #expect(c2 == .medium)
    }

    @Test("determineConfidence — 6개 이상 + regular + shift 없음이면 high를 반환한다")
    func highCycleCountRegularNoShiftReturnsHigh() {
        let c = engine.determineConfidence(cleanCycleCount: 8, variability: .regular, shift: false)
        #expect(c == .high)
    }

    @Test("determineConfidence — 6개 이상 + regular + shift 있으면 medium으로 낮아진다")
    func highCycleCountWithShiftReturnsMedium() {
        let c = engine.determineConfidence(cleanCycleCount: 8, variability: .regular, shift: true)
        #expect(c == .medium)
    }

    @Test("determineConfidence — 6개 이상 + moderate이면 medium을 반환한다")
    func highCycleCountModerateReturnsMedium() {
        let c = engine.determineConfidence(cleanCycleCount: 7, variability: .moderate, shift: false)
        #expect(c == .medium)
    }
}

// MARK: - 7. Recency Weight

struct RecencyWeightTests {
    private let calendar = TestCalendar.make()
    private let engine = MenstrualPredictionEngine()

    @Test("recencyWeight — 같은 날짜이면 1.0을 반환한다")
    func sameDateReturns1() {
        let date = Self.date("2025-06-01")
        let w = engine.recencyWeight(for: date, latestDate: date, calendar: calendar)
        #expect(w == 1.0)
    }

    @Test("recencyWeight — 오래될수록 감소하지만 최소값(0.25) 이하로 떨어지지 않는다")
    func decaysButNeverBelowMinimum() {
        let latest = Self.date("2025-06-01")
        let old = Self.date("2023-01-01")  // 약 880일 전

        let w = engine.recencyWeight(for: old, latestDate: latest, calendar: calendar)

        #expect(w >= 0.25)
        #expect(w == 0.25)  // exp(-880/180) ≈ 0.007 → max(0.25, 0.007) = 0.25
    }

    @Test("recencyWeight — 중간 거리에서는 1.0과 최소값 사이의 값을 반환한다")
    func intermediateDistanceReturnsDecayedValue() {
        let latest = Self.date("2025-06-01")
        let mid = Self.date("2025-02-01")  // 약 120일 전

        let w = engine.recencyWeight(for: mid, latestDate: latest, calendar: calendar)

        // exp(-120/180) = exp(-0.666...) ≈ 0.513
        #expect(w > 0.25)
        #expect(w < 1.0)
    }

    private static func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}

// MARK: - 8. Adaptive Blend Weight

struct AdaptiveBlendWeightTests {
    private let engine = MenstrualPredictionEngine()

    // MARK: Cycle blend

    @Test("adaptiveCycleBlendWeight — 기록 0~2개이면 veryLow weight(0.30)를 반환한다")
    func veryLowHistoryReturnsCycleWeight030() {
        #expect(engine.adaptiveCycleBlendWeight(usedRecordCount: 0, confidence: .low) == 0.30)
        #expect(engine.adaptiveCycleBlendWeight(usedRecordCount: 2, confidence: .low) == 0.30)
    }

    @Test("adaptiveCycleBlendWeight — 기록 3~5개이면 low weight(0.15)를 반환한다")
    func lowHistoryReturnsCycleWeight015() {
        #expect(engine.adaptiveCycleBlendWeight(usedRecordCount: 3, confidence: .medium) == 0.15)
        #expect(engine.adaptiveCycleBlendWeight(usedRecordCount: 5, confidence: .medium) == 0.15)
    }

    @Test("adaptiveCycleBlendWeight — 기록 6개 이상이면 high weight(0.08)를 반환한다")
    func highHistoryReturnsCycleWeight008() {
        #expect(engine.adaptiveCycleBlendWeight(usedRecordCount: 6, confidence: .medium) == 0.08)
        #expect(engine.adaptiveCycleBlendWeight(usedRecordCount: 12, confidence: .medium) == 0.08)
    }

    @Test("adaptiveCycleBlendWeight — confidence가 high이면 기록 수 무관하게 override(0.03)를 반환한다")
    func highConfidenceOverridesToMinimalWeight() {
        #expect(engine.adaptiveCycleBlendWeight(usedRecordCount: 0, confidence: .high) == 0.03)
        #expect(engine.adaptiveCycleBlendWeight(usedRecordCount: 10, confidence: .high) == 0.03)
    }

    // MARK: Period blend

    @Test("adaptivePeriodBlendWeight — 기록 0~2개이면 0.30, 3~5개이면 0.20, 6개 이상이면 0.12를 반환한다")
    func periodBlendWeightByRecordCount() {
        #expect(engine.adaptivePeriodBlendWeight(usedRecordCount: 1) == 0.30)
        #expect(engine.adaptivePeriodBlendWeight(usedRecordCount: 4) == 0.20)
        #expect(engine.adaptivePeriodBlendWeight(usedRecordCount: 8) == 0.12)
    }
}

// MARK: - 9. Period 예측

struct PeriodPredictionTests {
    private let calendar = TestCalendar.make()
    private let engine = MenstrualPredictionEngine()

    @Test("predictPeriodLength — 빈 배열이면 nil을 반환한다")
    func emptyPeriodsReturnNil() {
        #expect(engine.predictPeriodLength(from: [], variability: .regular) == nil)
    }

    @Test("predictPeriodLength — 6개 미만이면 단순 중앙값을 사용한다")
    func underSixUsesSimpleMedian() {
        let periods = [
            PeriodSample(startDate: Self.date("2025-01-01"), periodLength: 4),
            PeriodSample(startDate: Self.date("2025-02-01"), periodLength: 6),
            PeriodSample(startDate: Self.date("2025-03-01"), periodLength: 5)
        ]

        let result = engine.predictPeriodLength(from: periods, variability: .regular)

        #expect(result == 5)  // median([4,5,6]) = 5
    }

    @Test("predictPeriodLength — 6개 이상이면 variability에 따라 short-term과 long-term을 혼합한다")
    func sixOrMoreUsesWeightedMix() {
        let periods = [
            PeriodSample(startDate: Self.date("2025-01-01"), periodLength: 4),
            PeriodSample(startDate: Self.date("2025-01-29"), periodLength: 4),
            PeriodSample(startDate: Self.date("2025-02-26"), periodLength: 5),
            PeriodSample(startDate: Self.date("2025-03-26"), periodLength: 5),
            PeriodSample(startDate: Self.date("2025-04-23"), periodLength: 6),
            PeriodSample(startDate: Self.date("2025-05-21"), periodLength: 6)
        ]

        let regular = engine.predictPeriodLength(from: periods, variability: .regular)
        let irregular = engine.predictPeriodLength(from: periods, variability: .irregular)

        #expect(regular == 5)
        #expect(irregular == 6)
    }

    @Test("predictPeriodLength — period length가 1 미만으로 계산되어도 최소 1을 반환한다")
    func minimumPeriodLengthIs1() {
        let periods = [
            PeriodSample(startDate: Self.date("2025-01-01"), periodLength: 1),
            PeriodSample(startDate: Self.date("2025-02-01"), periodLength: 1),
            PeriodSample(startDate: Self.date("2025-03-01"), periodLength: 1),
            PeriodSample(startDate: Self.date("2025-04-01"), periodLength: 1),
            PeriodSample(startDate: Self.date("2025-05-01"), periodLength: 1),
            PeriodSample(startDate: Self.date("2025-06-01"), periodLength: 1)
        ]

        let result = engine.predictPeriodLength(from: periods, variability: .regular)

        #expect(result == 1)
    }

    private static func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}

// MARK: - 10. Cycle 예측 (Case별)

struct CyclePredictionTests {
    private let calendar = TestCalendar.make()
    private let engine = MenstrualPredictionEngine()

    @Test("predictCycleLength — cycle 0개이면 nil을 반환한다")
    func zeroCyclesReturnNil() {
        let (value, shift) = engine.predictCycleLength(from: [], calendar: calendar)
        #expect(value == nil)
        #expect(shift == false)
    }

    @Test("predictCycleLength — cycle 1개이면 그 값을 그대로 반환한다")
    func singleCycleReturnsItself() {
        let samples = [
            CycleSample(startDate: Self.date("2025-01-29"), cycleLength: 31, weightFactor: 1.0)
        ]

        let (value, shift) = engine.predictCycleLength(from: samples, calendar: calendar)

        #expect(value == 31)
        #expect(shift == false)
    }

    @Test("predictCycleLength — cycle 2개이면 중앙값을 반환한다")
    func twoCyclesReturnsMedian() {
        let samples = [
            CycleSample(startDate: Self.date("2025-01-29"), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-02-26"), cycleLength: 30, weightFactor: 1.0)
        ]

        let (value, _) = engine.predictCycleLength(from: samples, calendar: calendar)

        #expect(value == 29)  // median([28,30]) = 29
    }

    @Test("predictCycleLength — cycle 3~4개이면 축소 adaptive 모델(EWMA + median)을 사용한다")
    func threeToFourCyclesUseReducedAdaptive() {
        let samples = [
            CycleSample(startDate: Self.date("2025-01-29"), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-02-26"), cycleLength: 29, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-03-28"), cycleLength: 30, weightFactor: 1.0)
        ]

        let (value, shift) = engine.predictCycleLength(from: samples, calendar: calendar)

        #expect(value != nil)
        #expect(shift == false)
    }

    @Test("predictCycleLength — cycle 5개 이상이면 full adaptive 모델을 사용하고 shift를 감지한다")
    func fiveOrMoreCyclesUseFullAdaptiveWithShiftDetection() {
        // cycles: [28,28,28,35,35,35] → shift 감지
        let samples = [
            CycleSample(startDate: Self.date("2025-01-29"), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-02-26"), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-03-26"), cycleLength: 28, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-04-23"), cycleLength: 35, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-05-28"), cycleLength: 35, weightFactor: 1.0),
            CycleSample(startDate: Self.date("2025-07-02"), cycleLength: 35, weightFactor: 1.0)
        ]

        let (value, shift) = engine.predictCycleLength(from: samples, calendar: calendar)

        #expect(value != nil)
        #expect(shift == true)
    }

    private static func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}

// MARK: - 11. 예측 레코드 생성

struct BuildPredictionsTests {
    private let calendar = TestCalendar.make()

    @Test("buildMenstrualPredictions — 지정된 개수만큼 연쇄 예측을 생성한다")
    func generatesConsecutiveRecords() {
        let anchor = Self.date("2026-04-01")

        let predictions = MenstrualPredictionEngine.buildMenstrualPredictions(
            from: anchor, cycleLength: 28, periodLength: 5, count: 3, calendar: calendar
        )

        #expect(predictions.count == 3)
        #expect(predictions.allSatisfy { $0.type == .menstrualPrediction })

        #expect(Self.dayString(predictions[0].startDate) == "2026-04-29")
        #expect(Self.dayString(predictions[0].endDate) == "2026-05-03")
        #expect(Self.dayString(predictions[1].startDate) == "2026-05-27")
        #expect(Self.dayString(predictions[2].startDate) == "2026-06-24")
    }

    @Test("buildMenstrualPredictions — count가 0이면 빈 배열을 반환한다")
    func zeroCountReturnsEmpty() {
        let predictions = MenstrualPredictionEngine.buildMenstrualPredictions(
            from: Self.date("2026-01-01"), cycleLength: 28, periodLength: 5, count: 0, calendar: calendar
        )
        #expect(predictions.isEmpty)
    }

    @Test("buildMenstrualPredictions — 각 예측의 endDate는 startDate + (periodLength - 1)일이다")
    func endDateIsPeriodLengthMinusOneFromStart() {
        let predictions = MenstrualPredictionEngine.buildMenstrualPredictions(
            from: Self.date("2026-01-01"), cycleLength: 30, periodLength: 7, count: 1, calendar: calendar
        )

        #expect(Self.dayString(predictions[0].startDate) == "2026-01-31")
        #expect(Self.dayString(predictions[0].endDate) == "2026-02-06")
    }

    private static func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }

    private static func dayString(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 12. Median 유틸리티

struct MedianTests {
    @Test("median — 홀수 개 배열의 가운데 값을 반환한다")
    func oddCountReturnsMiddle() {
        #expect(MenstrualPredictionEngine.median([1, 2, 3]) == 2.0)
        #expect(MenstrualPredictionEngine.median([10, 20, 30, 40, 50]) == 30.0)
    }

    @Test("median — 짝수 개 배열의 두 가운데 값 평균을 반환한다")
    func evenCountReturnsAverage() {
        #expect(MenstrualPredictionEngine.median([1, 2, 3, 4]) == 2.5)
        #expect(MenstrualPredictionEngine.median([28, 30]) == 29.0)
    }

    @Test("median — 빈 배열이면 0을 반환한다")
    func emptyReturnsZero() {
        #expect(MenstrualPredictionEngine.median([]) == 0)
    }

    @Test("median — 1개 배열이면 그 값을 반환한다")
    func singleElementReturnsItself() {
        #expect(MenstrualPredictionEngine.median([42]) == 42.0)
    }
}

// MARK: - 13. UserInputMode 제어

struct BlendControlTests {
    private let calendar = TestCalendar.make()

    @Test("notBlendUserInput이면 사용자 입력이 있어도 모델 예측만 사용한다")
    func blendOffIgnoresUserInput() {
        let noBlendEngine = MenstrualPredictionEngine(userInputMode: .notBlendUserInput)

        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            makeRecord(start: "2025-02-28", end: "2025-03-04")
        ]

        let withoutInput = noBlendEngine.predict(from: records, calendar: calendar)
        let withInput = noBlendEngine.predict(
            from: records,
            userInput: MenstrualUserInput(cycleLength: 35, periodLength: 8),
            calendar: calendar
        )

        #expect(withoutInput.predictedCycleLength == withInput.predictedCycleLength)
        #expect(withoutInput.predictedPeriodLength == withInput.predictedPeriodLength)
    }

    @Test("notBlendUserInput이고 기록 0개이면 통계 기본값(주기 28일, 기간 5일)으로 fallback 예측한다")
    func blendOffZeroRecordsFallbacksToDefault() {
        let noBlendEngine = MenstrualPredictionEngine(userInputMode: .notBlendUserInput)

        let result = noBlendEngine.predict(
            from: [],
            userInput: MenstrualUserInput(cycleLength: 28, periodLength: 5),
            calendar: calendar
        )

        #expect(result.confidence == .low)
        #expect(result.predictedCycleLength == 28)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.usedDefaultRule == true)
        #expect(result.menstrualPredictions.count == 3)
    }

    @Test("notBlendUserInput이고 기록 1개이면 통계 기본값 주기로 fallback하고 실제 period는 유지한다")
    func blendOffOneRecordFallbacksToDefaultCycle() {
        let noBlendEngine = MenstrualPredictionEngine(userInputMode: .notBlendUserInput)

        let records = [makeRecord(start: "2026-01-10", end: "2026-01-14")]

        let result = noBlendEngine.predict(
            from: records,
            userInput: MenstrualUserInput(cycleLength: 30, periodLength: 5),
            calendar: calendar
        )

        #expect(result.confidence == .low)
        #expect(result.predictedCycleLength == 28)  // 통계 기본값
        #expect(result.predictedPeriodLength == 5)   // 실제 기록의 period
        #expect(result.usedDefaultRule == true)
        #expect(result.menstrualPredictions.count == 3)
    }

    @Test("blendUserInput이면 기록 0개에서도 사용자 입력으로 예측을 생성한다")
    func blendOnZeroRecordsUsesUserInput() {
        let engine = MenstrualPredictionEngine(userInputMode: .blendUserInput)

        let result = engine.predict(
            from: [],
            userInput: MenstrualUserInput(cycleLength: 28, periodLength: 5),
            calendar: calendar
        )

        #expect(result.confidence == .low)
        #expect(result.predictedCycleLength == 28)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.menstrualPredictions.count == 3)
    }

    @Test("onlyUserInput이면 기록이 있어도 모델 예측 없이 사용자 입력값만 사용한다")
    func onlyUserInputUsesUserInputDirectly() {
        let onlyInputEngine = MenstrualPredictionEngine(userInputMode: .onlyUserInput)

        let records = [
            makeRecord(start: "2026-01-01", end: "2026-01-05"),
            makeRecord(start: "2026-01-30", end: "2026-02-03"),
            makeRecord(start: "2026-02-28", end: "2026-03-04"),
            makeRecord(start: "2026-03-28", end: "2026-04-01")
        ]

        let result = onlyInputEngine.predict(
            from: records,
            userInput: MenstrualUserInput(cycleLength: 35, periodLength: 7),
            calendar: calendar
        )

        // 모델 예측이 아닌 사용자 입력 35/7을 그대로 사용
        #expect(result.predictedCycleLength == 35)
        #expect(result.predictedPeriodLength == 7)
        #expect(result.confidence == .low)
        #expect(result.menstrualPredictions.count == 3)
    }

    @Test("onlyUserInput이고 userInput이 nil이면 통계 기본값으로 fallback한다")
    func onlyUserInputWithNilInputFallbacksToDefault() {
        let onlyInputEngine = MenstrualPredictionEngine(userInputMode: .onlyUserInput)

        let records = [
            makeRecord(start: "2026-01-01", end: "2026-01-05"),
            makeRecord(start: "2026-01-30", end: "2026-02-03")
        ]

        let result = onlyInputEngine.predict(
            from: records,
            userInput: nil,
            calendar: calendar
        )

        // userInput이 nil이면 모델 예측 경로로 fallback (effectiveUserInput = nil)
        #expect(result.predictedCycleLength != nil)
        #expect(result.predictedPeriodLength != nil)
        #expect(result.menstrualPredictions.count == 3)
    }

    private func makeRecord(start: String, end: String) -> MenstrualRecord {
        MenstrualRecord(
            type: .menstrualRecord,
            startDate: Self.date(start, calendar: calendar),
            endDate: Self.date(end, calendar: calendar)
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

}

// MARK: - 14. 사용자 입력 전용 예측 (predictFromUserInput)

struct PredictFromUserInputTests {
    private let calendar = TestCalendar.make()
    private let engine = MenstrualPredictionEngine()

    // MARK: 기본 동작

    @Test("유효한 cycle/period 입력 + 기록 있음 → 마지막 기록에 이어서 사용자 입력값으로 예측한다")
    func validInputWithRecordsGeneratesPredictionsFromLastRecord() {
        let records = [
            makeRecord(start: "2026-01-01", end: "2026-01-05"),
            makeRecord(start: "2026-01-29", end: "2026-02-02")
        ]

        let result = engine.predictFromUserInput(
            MenstrualUserInput(cycleLength: 30, periodLength: 6),
            records: records,
            calendar: calendar
        )

        #expect(result.predictedCycleLength == 30)
        #expect(result.predictedPeriodLength == 6)
        #expect(result.usedRecordCount == 2)
        #expect(result.usedDefaultRule == false)
        #expect(result.confidence == .low)
        #expect(result.menstrualPredictions.count == 3)

        // 마지막 기록 01-29 + 30일 = 02-28
        #expect(Self.dayString(result.menstrualPredictions[0].startDate) == "2026-02-28")
        #expect(Self.dayString(result.menstrualPredictions[0].endDate) == "2026-03-05")
        // 02-28 + 30일 = 03-30
        #expect(Self.dayString(result.menstrualPredictions[1].startDate) == "2026-03-30")
        // 03-30 + 30일 = 04-29
        #expect(Self.dayString(result.menstrualPredictions[2].startDate) == "2026-04-29")
    }

    @Test("기록 없이 사용자 입력만 → 현재 날짜를 기준으로 예측한다")
    func noRecordsUsesCurrentDateAsAnchor() {
        let result = engine.predictFromUserInput(
            MenstrualUserInput(cycleLength: 28, periodLength: 5),
            records: [],
            calendar: calendar
        )

        #expect(result.predictedCycleLength == 28)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.usedRecordCount == 0)
        #expect(result.usedDefaultRule == false)
        #expect(result.menstrualPredictions.count == 3)
    }

    @Test("진행 중 기록(endDate nil)이 있으면 해당 startDate를 기준으로 예측하고 월경 예정기간으로 치환한다")
    func openRecordIsUsedAsAnchorAndReplaced() {
        let records: [MenstrualRecord] = [
            makeRecord(start: "2026-01-01", end: "2026-01-05"),
            makeRecord(start: "2026-01-29", end: "2026-02-02"),
            MenstrualRecord(
                type: .menstrualRecord,
                startDate: Self.date("2026-02-26"),
                endDate: nil
            )
        ]

        let result = engine.predictFromUserInput(
            MenstrualUserInput(cycleLength: 30, periodLength: 6),
            records: records,
            calendar: calendar
        )

        #expect(result.usedRecordCount == 3)
        #expect(result.menstrualPredictions.count == 4)
        // 진행 중 기록이 예측으로 치환됨
        #expect(Self.dayString(result.menstrualPredictions[0].startDate) == "2026-02-26")
        #expect(Self.dayString(result.menstrualPredictions[0].endDate) == "2026-03-03")
        #expect(result.menstrualPredictions[0].type == .menstrualPrediction)
        // 이후 예측: 02-26 + 30 = 03-28
        #expect(Self.dayString(result.menstrualPredictions[1].startDate) == "2026-03-28")
    }

    // MARK: Fallback 동작

    @Test("cycle이 nil이면 기본값(28일)으로 대체한다")
    func nilCycleFallbacksToDefault() {
        let records = [makeRecord(start: "2026-01-01", end: "2026-01-05")]

        let result = engine.predictFromUserInput(
            MenstrualUserInput(cycleLength: nil, periodLength: 5),
            records: records,
            calendar: calendar
        )

        #expect(result.predictedCycleLength == 28)
        #expect(result.usedDefaultRule == true)
        // 01-01 + 28 = 01-29
        #expect(Self.dayString(result.menstrualPredictions[0].startDate) == "2026-01-29")
    }

    @Test("period가 nil이면 기본값(5일)으로 대체한다")
    func nilPeriodFallbacksToDefault() {
        let records = [makeRecord(start: "2026-01-01", end: "2026-01-05")]

        let result = engine.predictFromUserInput(
            MenstrualUserInput(cycleLength: 30, periodLength: nil),
            records: records,
            calendar: calendar
        )

        #expect(result.predictedPeriodLength == 5)
        #expect(result.usedDefaultRule == true)
    }

    @Test("유효 범위 밖 cycle → 기본값(28일)으로 대체한다")
    func outOfRangeCycleFallbacksToDefault() {
        let result = engine.predictFromUserInput(
            MenstrualUserInput(cycleLength: 200, periodLength: 5),
            calendar: calendar
        )

        #expect(result.predictedCycleLength == 28)
        #expect(result.usedDefaultRule == true)
    }

    @Test("유효 범위 밖 period → 기본값(5일)으로 대체한다")
    func outOfRangePeriodFallbacksToDefault() {
        let result = engine.predictFromUserInput(
            MenstrualUserInput(cycleLength: 30, periodLength: 50),
            calendar: calendar
        )

        #expect(result.predictedPeriodLength == 5)
        #expect(result.usedDefaultRule == true)
    }

    @Test("cycle/period 모두 nil이면 기본값(주기 28일, 기간 5일)으로 예측한다")
    func bothNilFallbacksToDefaults() {
        let result = engine.predictFromUserInput(
            MenstrualUserInput(cycleLength: nil, periodLength: nil),
            calendar: calendar
        )

        #expect(result.predictedCycleLength == 28)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.usedDefaultRule == true)
        #expect(result.menstrualPredictions.count == 3)
    }

    // MARK: predict()와의 차이

    @Test("predict()와 달리 모델 예측을 사용하지 않고 사용자 입력값을 그대로 사용한다")
    func usesUserInputDirectlyWithoutModelPrediction() {
        // 기록은 28일 규칙적 주기이지만, 사용자가 35일로 입력하면 35일로 예측
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            makeRecord(start: "2025-02-26", end: "2025-03-02")
        ]

        let userInputResult = engine.predictFromUserInput(
            MenstrualUserInput(cycleLength: 35, periodLength: 7),
            records: records,
            calendar: calendar
        )

        let modelResult = engine.predict(
            from: records,
            userInput: MenstrualUserInput(cycleLength: 35, periodLength: 7),
            calendar: calendar
        )

        // predictFromUserInput은 사용자 입력값(35)을 그대로 사용
        #expect(userInputResult.predictedCycleLength == 35)
        #expect(userInputResult.predictedPeriodLength == 7)

        // predict()는 모델 예측과 blend하므로 35보다 작은 값
        #expect(modelResult.predictedCycleLength != 35)
    }

    private func makeRecord(start: String, end: String) -> MenstrualRecord {
        MenstrualRecord(
            type: .menstrualRecord,
            startDate: Self.date(start),
            endDate: Self.date(end)
        )
    }

    private static func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }

    private static func dayString(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 15. 통합 예측 (Case별 predict 흐름)

struct IntegrationPredictionTests {
    private let calendar = TestCalendar.make()
    private let engine = MenstrualPredictionEngine()

    // MARK: Case 0 — 유효 기록 0개

    @Test("기록 0개 + 사용자 입력 없음 → 통계 기본값(주기 28일, 기간 5일)으로 fallback 예측")
    func case0_noInput_fallbackToDefault() {
        let result = engine.predict(from: [], calendar: calendar)

        #expect(result.predictedCycleLength == 28)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .low)
        #expect(result.usedRecordCount == 0)
        #expect(result.usedDefaultRule == true)
        #expect(result.menstrualPredictions.count == 3)
    }

    @Test("기록 0개 + 유효한 사용자 입력 → 해당 값으로 예측 생성, low confidence")
    func case0_validInput_predictionsGenerated() {
        let result = engine.predict(
            from: [],
            userInput: MenstrualUserInput(cycleLength: 30, periodLength: 6),
            calendar: calendar
        )

        #expect(result.predictedCycleLength == 30)
        #expect(result.predictedPeriodLength == 6)
        #expect(result.confidence == .low)
        #expect(result.usedRecordCount == 0)
        #expect(result.menstrualPredictions.count == 3)
    }

    @Test("기록 0개 + cycle만 입력(period 없음) → 통계 기본값으로 fallback 예측")
    func case0_cycleOnlyInput_fallbackToDefault() {
        let result = engine.predict(
            from: [],
            userInput: MenstrualUserInput(cycleLength: 28, periodLength: nil),
            calendar: calendar
        )

        #expect(result.predictedCycleLength == 28)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .low)
        #expect(result.usedDefaultRule == true)
        #expect(result.menstrualPredictions.count == 3)
    }

    @Test("기록 0개 + 유효 범위 밖 사용자 입력 → 통계 기본값으로 fallback 예측")
    func case0_outOfRangeInput_fallbackToDefault() {
        let result = engine.predict(
            from: [],
            userInput: MenstrualUserInput(cycleLength: 200, periodLength: 5),
            calendar: calendar
        )

        #expect(result.predictedCycleLength == 28)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .low)
        #expect(result.usedDefaultRule == true)
        #expect(result.menstrualPredictions.count == 3)
    }

    // MARK: Case 1 — 유효 기록 1개

    @Test("기록 1개 + cycle 입력 있음 → 실제 period 유지, 입력 cycle로 예측")
    func case1_withCycleInput() {
        let records = [makeRecord(start: "2026-01-10", end: "2026-01-14")]

        let result = engine.predict(
            from: records,
            userInput: MenstrualUserInput(cycleLength: 30, periodLength: nil),
            calendar: calendar
        )

        #expect(result.predictedCycleLength == 30)
        #expect(result.predictedPeriodLength == 5)  // 실제 period = 5일
        #expect(result.confidence == .low)
        #expect(result.usedRecordCount == 1)
        #expect(result.menstrualPredictions.count == 3)
        #expect(Self.dayString(result.menstrualPredictions[0].startDate) == "2026-02-09")
    }

    @Test("기록 1개 + cycle 입력 없음 → 통계 기본값 주기로 fallback하고 실제 period 유지")
    func case1_noCycleInput_fallbackToDefaultCycle() {
        let records = [makeRecord(start: "2026-01-10", end: "2026-01-14")]

        let result = engine.predict(
            from: records,
            userInput: MenstrualUserInput(cycleLength: nil, periodLength: 5),
            calendar: calendar
        )

        #expect(result.predictedCycleLength == 28)  // 통계 기본값
        #expect(result.predictedPeriodLength == 5)   // 실제 기록의 period
        #expect(result.confidence == .low)
        #expect(result.usedDefaultRule == true)
        #expect(result.menstrualPredictions.count == 3)
        #expect(Self.dayString(result.menstrualPredictions[0].startDate) == "2026-02-07")
    }

    @Test("기록 1개 + cycle/period 모두 입력 → period는 실제값 우선으로 adaptive blend한다")
    func case1_withBothInputs_blendsPeriod() {
        let records = [makeRecord(start: "2026-01-10", end: "2026-01-14")]

        let result = engine.predict(
            from: records,
            userInput: MenstrualUserInput(cycleLength: 30, periodLength: 6),
            calendar: calendar
        )

        // 실제 period = 5, user = 6, weight = 0.30 (veryLow)
        // blended = (1-0.30)*5 + 0.30*6 = 3.5 + 1.8 = 5.3 → 5
        #expect(result.predictedCycleLength == 30)
        #expect(result.predictedPeriodLength == 5)
    }

    // MARK: Case 2 — 유효 기록 2개

    @Test("기록 2개 → 단일 cycle 기반 예측, low confidence")
    func case2_twoRecords() {
        let records = [
            makeRecord(start: "2026-01-01", end: "2026-01-05"),
            makeRecord(start: "2026-01-30", end: "2026-02-03")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.predictedCycleLength == 29)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .low)
        #expect(result.usedRecordCount == 2)
        #expect(result.menstrualPredictions.count == 3)

        #expect(result.menstrualPredictions[0].type == .menstrualPrediction)
        #expect(Self.dayString(result.menstrualPredictions[0].startDate) == "2026-02-28")
    }

    // MARK: Case 3 — 유효 기록 3개

    @Test("기록 3개 → cycle 2개의 중앙값으로 예측, low confidence")
    func case3_threeRecords() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            makeRecord(start: "2025-02-28", end: "2025-03-04")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.predictedCycleLength == 29)  // median([28,30]) = 29
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .low)
        #expect(result.usedRecordCount == 3)
    }

    @Test("진행 중 기록(endDate nil)이 있으면 startDate를 반영해 예측하고 해당 기록을 월경 예정기간으로 치환한다")
    func openEndedRecordIsReplacedWithPrediction() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            MenstrualRecord(
                type: .menstrualRecord,
                startDate: Self.date("2025-02-26", calendar: calendar),
                endDate: nil
            )
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.predictedCycleLength == 28)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.usedRecordCount == 3)
        #expect(result.menstrualPredictions.count == 4)
        #expect(result.menstrualPredictions[0].type == .menstrualPrediction)
        #expect(Self.dayString(result.menstrualPredictions[0].startDate) == "2025-02-26")
        #expect(Self.dayString(result.menstrualPredictions[0].endDate) == "2025-03-02")
        #expect(Self.dayString(result.menstrualPredictions[1].startDate) == "2025-03-26")
    }

    // MARK: Case 4 — 유효 기록 4~5개 (축소 adaptive)

    @Test("기록 4개 → 축소 adaptive 모델(EWMA + median), medium confidence")
    func case4_fourRecords() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            makeRecord(start: "2025-02-27", end: "2025-03-03"),
            makeRecord(start: "2025-03-29", end: "2025-04-02")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.predictedCycleLength == 29)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .medium)
        #expect(result.detectedShift == false)
    }

    // MARK: Case 5 — 유효 기록 7개 이상 (full adaptive)

    @Test("기록 7개 규칙적(range ≤ 4) → full adaptive, high confidence")
    func case5_regularCycles_highConfidence() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            makeRecord(start: "2025-02-26", end: "2025-03-02"),
            makeRecord(start: "2025-03-26", end: "2025-03-30"),
            makeRecord(start: "2025-04-23", end: "2025-04-27"),
            makeRecord(start: "2025-05-21", end: "2025-05-25"),
            makeRecord(start: "2025-06-18", end: "2025-06-22")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.predictedCycleLength == 28)
        #expect(result.predictedPeriodLength == 5)
        #expect(result.confidence == .high)
        #expect(result.detectedShift == false)
        #expect(result.usedRecordCount == 7)
        #expect(result.menstrualPredictions.count == 3)

        #expect(Self.dayString(result.menstrualPredictions[0].startDate) == "2025-07-16")
        #expect(Self.dayString(result.menstrualPredictions[0].endDate) == "2025-07-20")
    }

    @Test("기록 7개 moderate(range 5~8) → full adaptive, medium confidence")
    func case5_moderateCycles_mediumConfidence() {
        // cycles: [28, 31, 29, 32, 28, 36] → range=8 → moderate
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            makeRecord(start: "2025-03-01", end: "2025-03-05"),
            makeRecord(start: "2025-03-30", end: "2025-04-03"),
            makeRecord(start: "2025-05-01", end: "2025-05-05"),
            makeRecord(start: "2025-05-29", end: "2025-06-02"),
            makeRecord(start: "2025-07-04", end: "2025-07-08")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.confidence == .medium)
        #expect(result.detectedShift == false)
        #expect(result.predictedCycleLength != nil)
    }

    @Test("최근 주기가 갑자기 길어지면 shift를 감지하고 confidence를 낮춘다")
    func detectsShiftForSuddenLengthening() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            makeRecord(start: "2025-02-26", end: "2025-03-02"),
            makeRecord(start: "2025-03-26", end: "2025-03-30"),
            makeRecord(start: "2025-04-27", end: "2025-05-01"),
            makeRecord(start: "2025-05-29", end: "2025-06-02"),
            makeRecord(start: "2025-07-04", end: "2025-07-08")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.detectedShift == true)
        #expect(result.predictedCycleLength == 31)
        #expect(result.confidence == .medium)
    }

    // MARK: Blend

    @Test("사용자 입력이 있으면 adaptive weight로 예측값과 blend한다")
    func blendsWithAdaptiveWeight() {
        let customEngine = MenstrualPredictionEngine(config: {
            let c = MenstrualPredictionEngine.Config.default
            return MenstrualPredictionEngine.Config(
                validPeriodRange: c.validPeriodRange,
                validCycleRange: c.validCycleRange,
                allowedUserInputCycleRange: c.allowedUserInputCycleRange,
                allowedUserInputPeriodRange: c.allowedUserInputPeriodRange,
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
                recencyDecayDays: c.recencyDecayDays,
                recencyMinimumWeight: c.recencyMinimumWeight,
                userInputMode: c.userInputMode,
                userInputCycleWeightVeryLowHistory: 0.5,
                userInputCycleWeightLowHistory: 0.5,
                userInputCycleWeightHighHistory: 0.5,
                userInputCycleWeightHighConfidenceOverride: 0.5,
                userInputPeriodWeightVeryLowHistory: 0.5,
                userInputPeriodWeightLowHistory: 0.5,
                userInputPeriodWeightHighHistory: 0.5,
                shiftThreshold: c.shiftThreshold,
                predictionCount: c.predictionCount
            )
        }())

        let records = [
            makeRecord(start: "2026-01-01", end: "2026-01-05"),
            makeRecord(start: "2026-01-30", end: "2026-02-03")
        ]

        let result = customEngine.predict(
            from: records,
            userInput: MenstrualUserInput(cycleLength: 31, periodLength: 7),
            calendar: calendar
        )

        // cycle: (1-0.5)*29 + 0.5*31 = 30, period: (1-0.5)*5 + 0.5*7 = 6
        #expect(result.predictedCycleLength == 30)
        #expect(result.predictedPeriodLength == 6)
    }

    @Test("Config로 predictionCount를 변경하면 해당 개수만큼 예측한다")
    func customPredictionCount() {
        let customEngine = MenstrualPredictionEngine(config: {
            let c = MenstrualPredictionEngine.Config.default
            return MenstrualPredictionEngine.Config(
                validPeriodRange: c.validPeriodRange,
                validCycleRange: c.validCycleRange,
                allowedUserInputCycleRange: c.allowedUserInputCycleRange,
                allowedUserInputPeriodRange: c.allowedUserInputPeriodRange,
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
                recencyDecayDays: c.recencyDecayDays,
                recencyMinimumWeight: c.recencyMinimumWeight,
                userInputMode: c.userInputMode,
                userInputCycleWeightVeryLowHistory: c.userInputCycleWeightVeryLowHistory,
                userInputCycleWeightLowHistory: c.userInputCycleWeightLowHistory,
                userInputCycleWeightHighHistory: c.userInputCycleWeightHighHistory,
                userInputCycleWeightHighConfidenceOverride: c.userInputCycleWeightHighConfidenceOverride,
                userInputPeriodWeightVeryLowHistory: c.userInputPeriodWeightVeryLowHistory,
                userInputPeriodWeightLowHistory: c.userInputPeriodWeightLowHistory,
                userInputPeriodWeightHighHistory: c.userInputPeriodWeightHighHistory,
                shiftThreshold: c.shiftThreshold,
                predictionCount: 5
            )
        }())

        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02")
        ]

        let result = customEngine.predict(from: records, calendar: calendar)
        #expect(result.menstrualPredictions.count == 5)
    }

    private func makeRecord(start: String, end: String) -> MenstrualRecord {
        MenstrualRecord(
            type: .menstrualRecord,
            startDate: Self.date(start, calendar: calendar),
            endDate: Self.date(end, calendar: calendar)
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

    private static func dayString(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 16. 엣지 케이스

struct EdgeCaseTests {
    private let calendar = TestCalendar.make()
    private let engine = MenstrualPredictionEngine()

    @Test("주기가 갑자기 불규칙해진 경우 — 규칙적이었다가 마지막 3개가 흩어지면 confidence가 떨어진다")
    func suddenlyIrregularCyclesLowerConfidence() {
        // 처음 4개: 28일 규칙, 마지막 3개: 22,35,40일로 급변
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),  // 28
            makeRecord(start: "2025-02-26", end: "2025-03-02"),  // 28
            makeRecord(start: "2025-03-26", end: "2025-03-30"),  // 28
            makeRecord(start: "2025-04-23", end: "2025-04-27"),  // 28
            makeRecord(start: "2025-05-15", end: "2025-05-19"),  // 22
            makeRecord(start: "2025-06-19", end: "2025-06-23"),  // 35
            makeRecord(start: "2025-08-08", end: "2025-08-12")   // 40 → 범위 내
        ]

        let result = engine.predict(from: records, calendar: calendar)

        // 마지막 6개 cycle에서 range가 넓어지므로 confidence가 high가 아닐 것
        #expect(result.confidence != .high)
        #expect(result.predictedCycleLength != nil)
    }

    @Test("이상치가 1개 섞인 규칙적 데이터 — 이상치의 가중치만 낮아지고 예측은 안정적이다")
    func singleOutlierInRegularData() {
        // 6개 regular(28일) 중 1개가 60일(severe outlier)
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),  // 28
            makeRecord(start: "2025-02-26", end: "2025-03-02"),  // 28
            makeRecord(start: "2025-03-26", end: "2025-03-30"),  // 28
            makeRecord(start: "2025-05-25", end: "2025-05-29"),  // 60 → mild/severe outlier
            makeRecord(start: "2025-06-22", end: "2025-06-26"),  // 28
            makeRecord(start: "2025-07-20", end: "2025-07-24")   // 28
        ]

        let result = engine.predict(from: records, calendar: calendar)

        // 이상치 1개에도 불구하고 대부분 28일이므로 예측은 28~29 근처
        #expect(result.predictedCycleLength != nil)
        let cycle = result.predictedCycleLength!
        #expect((26...32).contains(cycle))
    }

    @Test("모든 기록이 동일한 주기일 때 — 예측도 동일한 값이고 high confidence이다")
    func perfectlyRegularCycles() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            makeRecord(start: "2025-02-26", end: "2025-03-02"),
            makeRecord(start: "2025-03-26", end: "2025-03-30"),
            makeRecord(start: "2025-04-23", end: "2025-04-27"),
            makeRecord(start: "2025-05-21", end: "2025-05-25"),
            makeRecord(start: "2025-06-18", end: "2025-06-22")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.predictedCycleLength == 28)
        #expect(result.confidence == .high)
        #expect(result.detectedShift == false)
    }

    @Test("period length가 유효 범위 하한(2일)인 기록이 유효하게 처리된다")
    func minimumPeriodLengthRecord() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-02"),  // 2일
            makeRecord(start: "2025-01-29", end: "2025-01-30")   // 2일
        ]

        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.predictedPeriodLength == 2)
        #expect(result.usedRecordCount == 2)
    }

    @Test("cycle length가 유효 범위 경계(20일, 45일)에서 포함된다")
    func cycleLengthAtBoundary() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-21", end: "2025-01-25"),  // 20일 cycle → 경계 포함
            makeRecord(start: "2025-03-07", end: "2025-03-11")   // 45일 cycle → 경계 포함
        ]

        let samples = engine.makeCycleSamples(
            from: engine.validateRecords(
                MenstrualPredictionEngine.extractActualRecords(from: records),
                calendar: calendar
            ),
            calendar: calendar
        )

        #expect(samples.map(\.cycleLength) == [20, 45])
    }

    @Test("기록이 시간순서 역순으로 들어와도 내부에서 정렬하여 정확히 예측한다")
    func outOfOrderRecordsAreSorted() {
        let records = [
            makeRecord(start: "2025-02-28", end: "2025-03-04"),
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02")
        ]

        let result = engine.predict(from: records, calendar: calendar)

        // 정렬 후: 01-01, 01-29, 02-28 → cycles: [28, 30] → median = 29
        #expect(result.predictedCycleLength == 29)
        #expect(result.usedRecordCount == 3)
    }

    @Test("사용자 입력 cycle이 유효 범위 밖이면 blend 시 무시된다")
    func outOfRangeUserInputCycleIsIgnored() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02")
        ]

        // 01-01 → 01-29 = 28일 cycle
        let result = engine.predict(
            from: records,
            userInput: MenstrualUserInput(cycleLength: 200, periodLength: 5),
            calendar: calendar
        )

        // cycle 200은 범위(20~45) 밖이므로 무시, 모델 예측값(28)만 사용
        #expect(result.predictedCycleLength == 28)
    }

    @Test("사용자 입력 period가 유효 범위 밖이면 blend 시 무시된다")
    func outOfRangeUserInputPeriodIsIgnored() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02")
        ]

        let result = engine.predict(
            from: records,
            userInput: MenstrualUserInput(cycleLength: 30, periodLength: 50),
            calendar: calendar
        )

        // period 50은 범위(2~8) 밖이므로 무시
        #expect(result.predictedPeriodLength == 5)
    }

    @Test("userInput 없이 호출해도 정상 동작한다")
    func noUserInputWorksCorrectly() {
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02")
        ]

        // 01-01 → 01-29 = 28일 cycle
        let result = engine.predict(from: records, calendar: calendar)

        #expect(result.predictedCycleLength == 28)
        #expect(result.predictedPeriodLength == 5)
    }

    @Test("점진적으로 길어지는 주기 패턴에서 EWMA가 추세를 반영한다")
    func graduallyLengeningCyclesReflectedInEWMA() {
        // 점점 길어지는 주기: 26 → 27 → 28 → 29 → 30 → 31
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-27", end: "2025-01-31"),  // 26
            makeRecord(start: "2025-02-23", end: "2025-02-27"),  // 27
            makeRecord(start: "2025-03-23", end: "2025-03-27"),  // 28
            makeRecord(start: "2025-04-21", end: "2025-04-25"),  // 29
            makeRecord(start: "2025-05-21", end: "2025-05-25"),  // 30
            makeRecord(start: "2025-06-21", end: "2025-06-25")   // 31
        ]

        let result = engine.predict(from: records, calendar: calendar)

        // EWMA는 최근 값(30,31)에 더 가중하므로 중앙값(28.5)보다 높을 것
        #expect(result.predictedCycleLength != nil)
        let cycle = result.predictedCycleLength!
        #expect(cycle >= 29)
    }

    @Test("high confidence에서 사용자 입력 blend weight는 최소(0.03)가 되어 모델 예측이 지배적이다")
    func highConfidenceMinimizesUserInputBlend() {
        // 7개 규칙적 기록(28일) → high confidence → cycle blend = 0.03
        let records = [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            makeRecord(start: "2025-02-26", end: "2025-03-02"),
            makeRecord(start: "2025-03-26", end: "2025-03-30"),
            makeRecord(start: "2025-04-23", end: "2025-04-27"),
            makeRecord(start: "2025-05-21", end: "2025-05-25"),
            makeRecord(start: "2025-06-18", end: "2025-06-22")
        ]

        let resultWithInput = engine.predict(
            from: records,
            userInput: MenstrualUserInput(cycleLength: 35, periodLength: 8),
            calendar: calendar
        )

        // model = 28, user = 35, weight = 0.03
        // blended = 0.97 * 28 + 0.03 * 35 = 27.16 + 1.05 = 28.21 → 28
        #expect(resultWithInput.predictedCycleLength == 28)
    }

    @Test("모든 cycle이 severe outlier(극단값)일 때 variabilityCycleLengths는 전체를 fallback으로 사용한다")
    func allSevereOutliersFallbackToAll() {
        let samples = [
            CycleSample(startDate: Date(), cycleLength: 15, weightFactor: 0.2),
            CycleSample(startDate: Date(), cycleLength: 80, weightFactor: 0.2),
            CycleSample(startDate: Date(), cycleLength: 50, weightFactor: 0.2)
        ]

        let lengths = engine.variabilityCycleLengths(from: samples)

        // 모두 severe → non-severe 0개 → fallback 전체
        #expect(lengths == [15, 80, 50])
    }

    private func makeRecord(start: String, end: String) -> MenstrualRecord {
        MenstrualRecord(
            type: .menstrualRecord,
            startDate: Self.date(start, calendar: calendar),
            endDate: Self.date(end, calendar: calendar)
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

    private static func dayString(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 17. MenstrualRecordUseCase

struct MenstrualRecordUseCaseTests {
    private let calendar = TestCalendar.make()

    @Test("fetchMenstrualOverview는 실제 월경 기록에 예상 월경, 배란일, 배란기를 합쳐 정렬해 반환한다")
    func fetchMenstrualOverviewIncludesPredictionsAndOvulationRecords() async throws {
        let repository = MockHealthKitRepository(records: [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            makeRecord(start: "2025-02-26", end: "2025-03-02")
        ])
        let useCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: repository,
            calendar: calendar
        )

        let overview = try await useCase.fetchMenstrualOverview()
        let result = overview.allRecords

        #expect(result.filter { $0.type == .menstrualRecord }.count == 3)
        #expect(result.filter { $0.type == .menstrualPrediction }.count == 3)
        #expect(result.filter { $0.type == .ovulationEstimated }.count == 3)
        #expect(result.filter { $0.type == .ovulationFertileWindowEstimated }.count == 3)
        #expect(result.filter { $0.type == .ovulationPrediction }.count == 3)
        #expect(result.filter { $0.type == .ovulationFertileWindowPrediction }.count == 3)
        #expect(result.count == 18)
        #expect(result.map(\.startDate) == result.map(\.startDate).sorted())
    }

    @Test("fetchMenstrualOverview는 기록이 없으면 통계 기본값 기반 예측(주기 28일, 기간 5일)과 배란 기록을 반환한다")
    func fetchMenstrualOverviewReturnsDefaultPredictionsWhenNoActualRecords() async throws {
        let repository = MockHealthKitRepository(records: [])
        let useCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: repository,
            calendar: calendar
        )

        let overview = try await useCase.fetchMenstrualOverview()
        let result = overview.allRecords

        #expect(result.filter { $0.type == .menstrualRecord }.count == 0)
        #expect(result.filter { $0.type == .menstrualPrediction }.count == 3)
    }

    @Test("fetchMenstrualOverview는 전달된 사용자 입력을 예측에 반영한다")
    func fetchMenstrualOverviewUsesUserInput() async throws {
        let repository = MockHealthKitRepository(records: [])
        let useCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: repository,
            calendar: calendar
        )

        let overview = try await useCase.fetchMenstrualOverview(
            activeMenstrualStartDate: nil,
            userInput: MenstrualUserInput(cycleLength: 35, periodLength: 7),
            userInputMode: .blendUserInput
        )

        #expect(overview.prediction?.predictedCycleLength == 35)
        #expect(overview.prediction?.predictedPeriodLength == 7)
        #expect(overview.prediction?.menstrualPredictions.count == 3)
    }

    @Test("fetchMenstrualOverview는 notBlendUserInput이면 전달된 사용자 입력을 무시한다")
    func fetchMenstrualOverviewCanIgnoreUserInput() async throws {
        let repository = MockHealthKitRepository(records: [])
        let useCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: repository,
            calendar: calendar
        )

        let overview = try await useCase.fetchMenstrualOverview(
            activeMenstrualStartDate: nil,
            userInput: MenstrualUserInput(cycleLength: 35, periodLength: 7),
            userInputMode: .notBlendUserInput
        )

        #expect(overview.prediction?.predictedCycleLength == 28)
        #expect(overview.prediction?.predictedPeriodLength == 5)
        #expect(overview.prediction?.usedDefaultRule == true)
    }

    @Test("fetchMenstrualOverview는 userInputMode만 바꾸고 주입된 예측 엔진 config는 유지한다")
    func fetchMenstrualOverviewPreservesInjectedPredictionConfig() async throws {
        let repository = MockHealthKitRepository(records: [])
        let useCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: repository,
            predictionEngine: MenstrualPredictionEngine(
                config: Self.makePredictionConfig(predictionCount: 5)
            ),
            calendar: calendar
        )

        let overview = try await useCase.fetchMenstrualOverview(
            activeMenstrualStartDate: nil,
            userInput: MenstrualUserInput(cycleLength: 35, periodLength: 7),
            userInputMode: .onlyUserInput
        )

        #expect(overview.prediction?.predictedCycleLength == 35)
        #expect(overview.prediction?.predictedPeriodLength == 7)
        #expect(overview.prediction?.menstrualPredictions.count == 5)
    }

    @Test("fetchMenstrualOverview는 진행 중 실제 기록(endDate nil)을 제거하고 예측 월경 예정기간으로 교체한다")
    func fetchMenstrualOverviewReplacesOpenEndedActualRecord() async throws {
        let repository = MockHealthKitRepository(records: [
            makeRecord(start: "2025-01-01", end: "2025-01-05"),
            makeRecord(start: "2025-01-29", end: "2025-02-02"),
            MenstrualRecord(
                type: .menstrualRecord,
                startDate: Self.date("2025-02-26", calendar: calendar),
                endDate: nil
            )
        ])
        let useCase = MenstrualRecordUseCaseImpl(
            healthKitRepository: repository,
            calendar: calendar
        )

        let overview = try await useCase.fetchMenstrualOverview()
        let result = overview.allRecords

        #expect(result.filter { $0.type == .menstrualRecord }.count == 2)
        #expect(result.filter { $0.type == .menstrualPrediction }.count == 4)
        #expect(result.contains {
            $0.type == .menstrualPrediction &&
            Self.dayString($0.startDate, calendar: calendar) == "2025-02-26" &&
            Self.dayString($0.endDate, calendar: calendar) == "2025-03-02"
        })
        #expect(!result.contains {
            $0.type == .menstrualRecord &&
            Self.dayString($0.startDate, calendar: calendar) == "2025-02-26" &&
            $0.endDate == nil
        })
    }

    private func makeRecord(start: String, end: String) -> MenstrualRecord {
        MenstrualRecord(
            type: .menstrualRecord,
            startDate: Self.date(start, calendar: calendar),
            endDate: Self.date(end, calendar: calendar)
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

    private static func makePredictionConfig(
        predictionCount: Int
    ) -> MenstrualPredictionEngine.Config {
        let c = MenstrualPredictionEngine.Config.default
        return MenstrualPredictionEngine.Config(
            validPeriodRange: c.validPeriodRange,
            validCycleRange: c.validCycleRange,
            allowedUserInputCycleRange: c.allowedUserInputCycleRange,
            allowedUserInputPeriodRange: c.allowedUserInputPeriodRange,
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
            recencyDecayDays: c.recencyDecayDays,
            recencyMinimumWeight: c.recencyMinimumWeight,
            userInputMode: c.userInputMode,
            userInputCycleWeightVeryLowHistory: c.userInputCycleWeightVeryLowHistory,
            userInputCycleWeightLowHistory: c.userInputCycleWeightLowHistory,
            userInputCycleWeightHighHistory: c.userInputCycleWeightHighHistory,
            userInputCycleWeightHighConfidenceOverride: c.userInputCycleWeightHighConfidenceOverride,
            userInputPeriodWeightVeryLowHistory: c.userInputPeriodWeightVeryLowHistory,
            userInputPeriodWeightLowHistory: c.userInputPeriodWeightLowHistory,
            userInputPeriodWeightHighHistory: c.userInputPeriodWeightHighHistory,
            shiftThreshold: c.shiftThreshold,
            predictionCount: predictionCount
        )
    }
}

// MARK: - 18. EventKit Mapper

struct EventKitMapperTests {
    private let calendar = TestCalendar.make()

    @Test("종일 캘린더 이벤트로 내보낼 때 endDate는 마지막 날의 다음 날로 변환된다")
    func allDayEventUsesExclusiveEndDate() {
        let record = MenstrualRecord(
            type: .menstrualRecord,
            startDate: Self.date("2026-03-08", calendar: calendar),
            endDate: Self.date("2026-03-11", calendar: calendar)
        )

        let parameters = EventKitMapper.eventParameters(
            from: [record],
            calendar: calendar
        )

        #expect(parameters.count == 1)
        #expect(Self.dayString(parameters[0].startDate, calendar: calendar) == "2026-03-08")
        #expect(Self.dayString(parameters[0].endDate, calendar: calendar) == "2026-03-12")
    }

    private static func date(_ value: String, calendar: Calendar) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }

    private static func dayString(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 19. CurrentMenstrualStatusResolver (현재 월경 상태 판별)

struct CurrentMenstrualStatusResolverTests {
    private let calendar = TestCalendar.make()
    private let resolver = CurrentMenstrualStatusResolver()

    @Test("오늘 건강앱 월경 기록이 있으면 현재 월경 중으로 판단한다")
    func activeWhenTodayHasHealthRecord() {
        let status = resolver.resolve(
            actualRecords: [
                makeRecord(start: "2026-01-10", end: "2026-01-12")
            ],
            currentEpisode: nil,
            predictedPeriodLength: 5,
            today: date("2026-01-12"),
            calendar: calendar
        )

        #expect(status.isActive)
        #expect(status.activeStartDate == date("2026-01-10"))
        #expect(status.expectedEndDate == date("2026-01-14"))
    }

    @Test("오늘 기록이 없어도 최신 시작일이 자동 종료 기준 전이면 현재 월경 중으로 판단한다")
    func activeWithinAutoCloseWindowWithoutTodaySample() {
        let status = resolver.resolve(
            actualRecords: [
                makeRecord(start: "2026-01-10", end: "2026-01-10")
            ],
            currentEpisode: nil,
            predictedPeriodLength: 5,
            today: date("2026-01-15"),
            calendar: calendar
        )

        #expect(status.isActive)
        #expect(status.shouldAutoClose == false)
        #expect(status.activeStartDate == date("2026-01-10"))
    }

    @Test("사용자가 종료한 에피소드는 자동 종료 기준 전이어도 현재 월경 중으로 판단하지 않는다")
    func userClosedEpisodeIsInactive() {
        let status = resolver.resolve(
            actualRecords: [
                makeRecord(start: "2026-01-10", end: "2026-01-10")
            ],
            currentEpisode: CurrentMenstrualEpisode(
                startDate: date("2026-01-10"),
                endDate: date("2026-01-12"),
                closedReason: .userEnded
            ),
            predictedPeriodLength: 5,
            today: date("2026-01-13"),
            calendar: calendar
        )

        #expect(status.isActive == false)
        #expect(status.shouldAutoClose == false)
    }

    @Test("사용자가 오늘 종료한 에피소드는 홈 표시용 월경 기간을 유지한다")
    func userClosedEpisodeTodayKeepsDisplayWindow() {
        let status = resolver.resolve(
            actualRecords: [
                makeRecord(start: "2026-05-01", end: "2026-05-03")
            ],
            currentEpisode: CurrentMenstrualEpisode(
                startDate: date("2026-05-01"),
                endDate: date("2026-05-03"),
                closedReason: .userEnded
            ),
            predictedPeriodLength: 5,
            today: date("2026-05-03"),
            calendar: calendar
        )

        #expect(status.isActive == false)
        #expect(status.displayWindow?.startDate == date("2026-05-01"))
        #expect(status.displayWindow?.endDate == date("2026-05-03"))
    }

    @Test("사용자가 종료한 에피소드는 다음 날 홈 표시용 월경 기간을 제거한다")
    func userClosedEpisodeAfterEndDateClearsDisplayWindow() {
        let status = resolver.resolve(
            actualRecords: [
                makeRecord(start: "2026-05-01", end: "2026-05-03")
            ],
            currentEpisode: CurrentMenstrualEpisode(
                startDate: date("2026-05-01"),
                endDate: date("2026-05-03"),
                closedReason: .userEnded
            ),
            predictedPeriodLength: 5,
            today: date("2026-05-04"),
            calendar: calendar
        )

        #expect(status.isActive == false)
        #expect(status.displayWindow == nil)
    }

    @Test("자동 종료 기준을 지나면 자동 종료 대상으로 판단한다")
    func detectsAutoCloseAfterDeadline() {
        let status = resolver.resolve(
            actualRecords: [
                makeRecord(start: "2026-01-10", end: "2026-01-10")
            ],
            currentEpisode: nil,
            predictedPeriodLength: 5,
            today: date("2026-01-17"),
            calendar: calendar
        )

        #expect(status.isActive == false)
        #expect(status.shouldAutoClose)
        #expect(status.latestStartDate == date("2026-01-10"))
        #expect(status.expectedEndDate == date("2026-01-14"))
    }

    @Test("건강앱 기록이 없으면 로컬 open episode가 있어도 현재 월경 중으로 판단하지 않는다")
    func inactiveWhenOnlyLocalOpenEpisodeExists() {
        let status = resolver.resolve(
            actualRecords: [],
            currentEpisode: CurrentMenstrualEpisode(
                startDate: date("2026-01-10"),
                endDate: nil,
                closedReason: nil
            ),
            predictedPeriodLength: 5,
            today: date("2026-01-12"),
            calendar: calendar
        )

        #expect(status.isActive == false)
        #expect(status.shouldAutoClose == false)
        #expect(status.activeStartDate == nil)
        #expect(status.latestStartDate == nil)
    }

    @Test("건강앱 최신 기록과 로컬 episode 시작일이 다르면 건강앱 기록만 기준으로 판단한다")
    func ignoresLocalEpisodeWhenStartDateDoesNotMatchLatestHealthRecord() {
        let status = resolver.resolve(
            actualRecords: [
                makeRecord(start: "2026-01-08", end: "2026-01-08")
            ],
            currentEpisode: CurrentMenstrualEpisode(
                startDate: date("2026-01-10"),
                endDate: nil,
                closedReason: nil
            ),
            predictedPeriodLength: 5,
            today: date("2026-01-12"),
            calendar: calendar
        )

        #expect(status.isActive)
        #expect(status.activeStartDate == date("2026-01-08"))
        #expect(status.latestStartDate == date("2026-01-08"))
    }

    @Test("열려 있는 앱 에피소드는 자동 종료 기준을 지나도 월경 중으로 유지하고 자동 종료 대상으로 표시한다")
    func openEpisodeAfterDeadlineStaysActiveAndRequiresAutoClose() {
        let status = resolver.resolve(
            actualRecords: [
                makeRecord(start: "2026-01-10", end: "2026-01-10")
            ],
            currentEpisode: CurrentMenstrualEpisode(
                startDate: date("2026-01-10"),
                endDate: nil,
                closedReason: nil
            ),
            predictedPeriodLength: 5,
            today: date("2026-01-17"),
            calendar: calendar
        )

        #expect(status.isActive)
        #expect(status.shouldAutoClose)
        #expect(status.activeStartDate == date("2026-01-10"))
        #expect(status.expectedEndDate == date("2026-01-14"))
    }

    private func makeRecord(start: String, end: String) -> MenstrualRecord {
        MenstrualRecord(
            type: .menstrualRecord,
            startDate: date(start),
            endDate: date(end)
        )
    }

    private func date(_ value: String) -> Date {
        Self.date(value, calendar: calendar)
    }

    private static func date(_ value: String, calendar: Calendar) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}

// MARK: - 20. OpenPeriodAutoCloser (자동 종료 판별)

struct OpenPeriodAutoCloserTests {
    private let calendar = TestCalendar.make()
    private let closer = OpenPeriodAutoCloser()

    // MARK: 자동 종료 성공

    @Test("예상 종료일 + 유예기간을 지난 경우 자동 종료된 기록을 반환한다")
    func closesAfterDeadline() {
        // 1/10 시작, 기간 5일 → 예상 종료 1/14, 유예 2일 → 마감 1/16
        // referenceDate = 1/17 → 자동 종료
        let openRecord = makeOpenRecord(start: "2026-01-10")

        let result = closer.tryAutoClose(
            openRecord: openRecord,
            predictedPeriodLength: 5,
            referenceDate: Self.date("2026-01-17", calendar: calendar),
            calendar: calendar
        )

        #expect(result != nil)
        #expect(Self.dayString(result!.startDate, calendar: calendar) == "2026-01-10")
        #expect(Self.dayString(result!.endDate!, calendar: calendar) == "2026-01-14")
        #expect(result!.type == .menstrualRecord)
    }

    @Test("예상 종료일 + 유예기간 다음 날에 정확히 자동 종료된다")
    func closesExactlyOneDayAfterDeadline() {
        // 1/1 시작, 기간 3일 → 예상 종료 1/3, 유예 2일 → 마감 1/5
        // referenceDate = 1/6 → 자동 종료
        let openRecord = makeOpenRecord(start: "2026-01-01")

        let result = closer.tryAutoClose(
            openRecord: openRecord,
            predictedPeriodLength: 3,
            referenceDate: Self.date("2026-01-06", calendar: calendar),
            calendar: calendar
        )

        #expect(result != nil)
        #expect(Self.dayString(result!.endDate!, calendar: calendar) == "2026-01-03")
    }

    // MARK: 자동 종료 미충족

    @Test("예상 종료일 + 유예기간 당일이면 아직 종료하지 않는다")
    func doesNotCloseOnDeadlineDay() {
        // 1/10 시작, 기간 5일 → 예상 종료 1/14, 유예 2일 → 마감 1/16
        // referenceDate = 1/16 → 마감 당일이므로 종료 안 됨
        let openRecord = makeOpenRecord(start: "2026-01-10")

        let result = closer.tryAutoClose(
            openRecord: openRecord,
            predictedPeriodLength: 5,
            referenceDate: Self.date("2026-01-16", calendar: calendar),
            calendar: calendar
        )

        #expect(result == nil)
    }

    @Test("예상 종료일 전이면 종료하지 않는다")
    func doesNotCloseBeforeExpectedEnd() {
        // 1/10 시작, 기간 5일 → 예상 종료 1/14
        // referenceDate = 1/12 → 아직 월경 기간 중
        let openRecord = makeOpenRecord(start: "2026-01-10")

        let result = closer.tryAutoClose(
            openRecord: openRecord,
            predictedPeriodLength: 5,
            referenceDate: Self.date("2026-01-12", calendar: calendar),
            calendar: calendar
        )

        #expect(result == nil)
    }

    // MARK: 이미 종료된 기록

    @Test("endDate가 이미 있는 기록이면 nil을 반환한다")
    func alreadyClosedRecordReturnsNil() {
        let closedRecord = MenstrualRecord(
            type: .menstrualRecord,
            startDate: Self.date("2026-01-10", calendar: calendar),
            endDate: Self.date("2026-01-14", calendar: calendar)
        )

        let result = closer.tryAutoClose(
            openRecord: closedRecord,
            predictedPeriodLength: 5,
            referenceDate: Self.date("2026-01-20", calendar: calendar),
            calendar: calendar
        )

        #expect(result == nil)
    }

    // MARK: 기간 1일

    @Test("월경 기간이 1일이면 시작일 = 종료일로 자동 종료한다")
    func periodLengthOneClosesOnStartDate() {
        // 1/10 시작, 기간 1일 → 예상 종료 1/10, 유예 2일 → 마감 1/12
        // referenceDate = 1/13 → 자동 종료
        let openRecord = makeOpenRecord(start: "2026-01-10")

        let result = closer.tryAutoClose(
            openRecord: openRecord,
            predictedPeriodLength: 1,
            referenceDate: Self.date("2026-01-13", calendar: calendar),
            calendar: calendar
        )

        #expect(result != nil)
        #expect(Self.dayString(result!.startDate, calendar: calendar) == "2026-01-10")
        #expect(Self.dayString(result!.endDate!, calendar: calendar) == "2026-01-10")
    }

    // MARK: 커스텀 유예기간

    @Test("유예기간을 0일로 설정하면 예상 종료일 다음 날부터 바로 종료한다")
    func zeroGracePeriodClosesImmediately() {
        let zeroGraceCloser = OpenPeriodAutoCloser(
            config: .init(gracePeriodDays: 0)
        )
        // 1/10 시작, 기간 5일 → 예상 종료 1/14, 유예 0일 → 마감 1/14
        // referenceDate = 1/15 → 자동 종료
        let openRecord = makeOpenRecord(start: "2026-01-10")

        let result = zeroGraceCloser.tryAutoClose(
            openRecord: openRecord,
            predictedPeriodLength: 5,
            referenceDate: Self.date("2026-01-15", calendar: calendar),
            calendar: calendar
        )

        #expect(result != nil)
        #expect(Self.dayString(result!.endDate!, calendar: calendar) == "2026-01-14")
    }

    @Test("유예기간을 5일로 설정하면 예상 종료일 + 5일 이후에 종료한다")
    func customGracePeriodDelaysClosure() {
        let longGraceCloser = OpenPeriodAutoCloser(
            config: .init(gracePeriodDays: 5)
        )
        // 1/10 시작, 기간 5일 → 예상 종료 1/14, 유예 5일 → 마감 1/19
        // referenceDate = 1/19 → 마감 당일, 아직 종료 안 됨
        let openRecord = makeOpenRecord(start: "2026-01-10")

        let notYet = longGraceCloser.tryAutoClose(
            openRecord: openRecord,
            predictedPeriodLength: 5,
            referenceDate: Self.date("2026-01-19", calendar: calendar),
            calendar: calendar
        )
        #expect(notYet == nil)

        // referenceDate = 1/20 → 종료
        let closed = longGraceCloser.tryAutoClose(
            openRecord: openRecord,
            predictedPeriodLength: 5,
            referenceDate: Self.date("2026-01-20", calendar: calendar),
            calendar: calendar
        )
        #expect(closed != nil)
        #expect(Self.dayString(closed!.endDate!, calendar: calendar) == "2026-01-14")
    }

    // MARK: - Helpers

    private func makeOpenRecord(start: String) -> MenstrualRecord {
        MenstrualRecord(
            type: .menstrualRecord,
            startDate: Self.date(start, calendar: calendar),
            endDate: nil
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

    private static func dayString(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private struct MockHealthKitRepository: HealthKitRepository {
    let records: [MenstrualRecord]

    func checkWriteAuthorization(for type: HealthDataType) async throws {}

    func requestAuthorization(
        writeTypes: Set<HealthDataType>,
        readTypes: Set<HealthDataType>
    ) async throws {}

    func readMenstrualCycleRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [MenstrualRecord] {
        records
    }

    func readWristTemperatureRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [WristTemperatureRecord] {
        []
    }

    func updateMenstrualCycleRecord(_ record: MenstrualRecord, deleteFrom: Date?, deleteThrough: Date?) async throws {}
}

// MARK: - Test Calendar Helper

private enum TestCalendar {
    static func make() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}
