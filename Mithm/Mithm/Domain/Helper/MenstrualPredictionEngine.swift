//
//  MenstrualPredictionEngine.swift
//  Mithm
//
//  Created by YunhakLee on 3/10/26.
//

import Foundation

// MARK: - Supporting Types

struct PeriodSample {
    let startDate: Date
    let periodLength: Int
}

struct CycleSample {
    let startDate: Date
    let cycleLength: Int
    let weightFactor: Double
}

enum CycleVariability {
    case regular
    case moderate
    case irregular
}

enum PredictionConfidence {
    case insufficient
    case low
    case medium
    case high
}

struct MenstrualUserInput {
    let cycleLength: Int?
    let periodLength: Int?
}

struct MenstrualPredictionResult {
    /// 다음 월경 예측 (최대 predictionCount개)
    let menstrualPredictions: [MenstrualRecord]

    let predictedCycleLength: Int?
    let predictedPeriodLength: Int?

    let confidence: PredictionConfidence
    let usedRecordCount: Int
    let detectedShift: Bool
    let usedDefaultRule: Bool
}

// MARK: - Prediction Engine

struct MenstrualPredictionEngine {

    // MARK: - Config

    struct Config {

        // MARK: 유효성 범위

        /// period length 유효 범위 (일수)
        let validPeriodRange: ClosedRange<Int>
        /// cycle length 유효 범위 (일수)
        let validCycleRange: ClosedRange<Int>

        // MARK: 이상치 가중치 (clean cycle)

        /// 중앙값 대비 편차가 이 값 이하이면 가중치 1.0
        let outlierNormalThreshold: Double
        /// 중앙값 대비 편차가 이 값 이하이면 가중치 reducedWeight
        let outlierMildThreshold: Double
        /// 경미한 이상치에 적용되는 가중치
        let outlierMildWeight: Double
        /// 심한 이상치에 적용되는 가중치
        let outlierSevereWeight: Double

        // MARK: 변동성 분류 (최근 cycle range 기준)

        /// range ≤ 이 값이면 regular
        let variabilityRegularMaxRange: Int
        /// range ≤ 이 값이면 moderate (초과 시 irregular)
        let variabilityModerateMaxRange: Int

        // MARK: EWMA alpha (변동성별)

        let ewmaAlphaRegular: Double
        let ewmaAlphaModerate: Double
        let ewmaAlphaIrregular: Double

        // MARK: Cycle 예측 혼합 비율 — short-term weight (long = 1 - short)

        /// 패턴 전환 없을 때 (regular)
        let cycleWeightRegular: Double
        /// 패턴 전환 없을 때 (moderate)
        let cycleWeightModerate: Double
        /// 패턴 전환 없을 때 (irregular)
        let cycleWeightIrregular: Double
        /// 패턴 전환 감지 시
        let cycleWeightShift: Double
        /// 축소 adaptive (기록 4~5개)
        let cycleWeightReduced: Double

        // MARK: Period 예측 혼합 비율 — short-term weight

        /// regular/moderate 일 때
        let periodWeightStable: Double
        /// irregular 일 때
        let periodWeightIrregular: Double

        // MARK: 사용자 입력 blend 비율 - user input weight

        /// 사용자 입력 cycle length를 최종 예측에 반영하는 비율
        let userInputCycleBlendWeight: Double
        /// 사용자 입력 period length를 최종 예측에 반영하는 비율
        let userInputPeriodBlendWeight: Double

        // MARK: Shift 감지

        /// 최근 3개 vs 이전 3~6개 중앙값 차이 임계값
        let shiftThreshold: Double

        // MARK: 예측 개수

        /// 앞으로 생성할 월경 예측 레코드 수
        let predictionCount: Int

        // MARK: Default

        static let `default` = Config(
            validPeriodRange: 1...15,
            validCycleRange: 15...90,
            
            outlierNormalThreshold: 5,
            outlierMildThreshold: 9,
            outlierMildWeight: 0.5,
            outlierSevereWeight: 0.2,
            
            variabilityRegularMaxRange: 3,
            variabilityModerateMaxRange: 7,
            
            ewmaAlphaRegular: 0.35,
            ewmaAlphaModerate: 0.45,
            ewmaAlphaIrregular: 0.55,
            
            cycleWeightRegular: 0.45,
            cycleWeightModerate: 0.60,
            cycleWeightIrregular: 0.75,
            cycleWeightShift: 0.85,
            cycleWeightReduced: 0.70,
            
            periodWeightStable: 0.40,
            periodWeightIrregular: 0.60,
            
            userInputCycleBlendWeight: 0.35,
            userInputPeriodBlendWeight: 0.35,
            
            shiftThreshold: 4.0,
            predictionCount: 3
        )
        
        static let launchDefault = Config(
            validPeriodRange: 2...8,
            validCycleRange: 20...45,

            outlierNormalThreshold: 4,
            outlierMildThreshold: 8,
            outlierMildWeight: 0.35,
            outlierSevereWeight: 0.10,

            variabilityRegularMaxRange: 4,
            variabilityModerateMaxRange: 8,

            ewmaAlphaRegular: 0.30,
            ewmaAlphaModerate: 0.45,
            ewmaAlphaIrregular: 0.60,

            cycleWeightRegular: 0.40,
            cycleWeightModerate: 0.60,
            cycleWeightIrregular: 0.80,
            cycleWeightShift: 0.90,
            cycleWeightReduced: 0.65,

            periodWeightStable: 0.35,
            periodWeightIrregular: 0.55,
            
            userInputCycleBlendWeight: 0.35,
            userInputPeriodBlendWeight: 0.35,

            shiftThreshold: 4.0,
            predictionCount: 3
        )
    }

    let config: Config

    init(config: Config = .default) {
        self.config = config
    }

    // MARK: - Public

    func predict(
        from records: [MenstrualRecord],
        userInput: MenstrualUserInput? = nil,
        calendar: Calendar = .current
    ) -> MenstrualPredictionResult {
        // 1) 실제 월경 기록 필터링 및 정렬
        let actualRecords = Self.extractActualRecords(from: records)

        // 2) 유효성 검증
        let validRecords = validateRecords(actualRecords, calendar: calendar)
        let recordCount = validRecords.count

        // Case 0: 유효 기록 0개
        guard !validRecords.isEmpty else {
            return MenstrualPredictionResult(
                menstrualPredictions: [],
                predictedCycleLength: nil,
                predictedPeriodLength: nil,
                confidence: .insufficient,
                usedRecordCount: 0,
                detectedShift: false,
                usedDefaultRule: false
            )
        }

        // 3) period / cycle 샘플 생성
        let periodSamples = makePeriodSamples(from: validRecords, calendar: calendar)
        let rawCycleSamples = makeCycleSamples(from: validRecords, calendar: calendar)

        // 4) clean cycle 생성
        let cleanCycles = cleanCycleSamples(rawCycleSamples)

        // Case 1: 유효 기록 1개 (cycle 정보 없음 → 예측 불가)
        if recordCount == 1 {
            return MenstrualPredictionResult(
                menstrualPredictions: [],
                predictedCycleLength: nil,
                predictedPeriodLength: nil,
                confidence: .insufficient,
                usedRecordCount: recordCount,
                detectedShift: false,
                usedDefaultRule: false
            )
        }

        // 5~8) 예측값 계산
        let (predCycle, shift) = predictCycleLength(from: cleanCycles)
        let variability: CycleVariability? = cleanCycles.count >= 2
            ? classifyVariability(from: cleanCycles.map(\.cycleLength))
            : nil
        let predPeriod = predictPeriodLength(from: periodSamples, variability: variability)
        let blendedCycle = blendCycleLength(predCycle, with: userInput?.cycleLength)
        let blendedPeriod = blendPeriodLength(predPeriod, with: userInput?.periodLength)

        guard let cycleLen = blendedCycle, let periodLen = blendedPeriod else {
            return MenstrualPredictionResult(
                menstrualPredictions: [],
                predictedCycleLength: blendedCycle,
                predictedPeriodLength: blendedPeriod,
                confidence: .low,
                usedRecordCount: recordCount,
                detectedShift: shift,
                usedDefaultRule: false
            )
        }

        // 9) 다음 월경 예측 생성
        let lastStartDay = calendar.startOfDay(for: validRecords.last!.startDate)
        let predictions = Self.buildMenstrualPredictions(
            from: lastStartDay,
            cycleLength: cycleLen,
            periodLength: periodLen,
            count: config.predictionCount,
            calendar: calendar
        )

        let confidence = determineConfidence(
            cleanCycleCount: cleanCycles.count,
            variability: variability,
            shift: shift
        )

        return MenstrualPredictionResult(
            menstrualPredictions: predictions,
            predictedCycleLength: cycleLen,
            predictedPeriodLength: periodLen,
            confidence: confidence,
            usedRecordCount: recordCount,
            detectedShift: shift,
            usedDefaultRule: false
        )
    }

    // MARK: - Step 1: Extract Actual Records

    static func extractActualRecords(from records: [MenstrualRecord]) -> [MenstrualRecord] {
        records
            .filter { $0.type == .menstrualRecord && $0.endDate != nil }
            .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - Step 2: Validate Records

    func validateRecords(
        _ records: [MenstrualRecord],
        calendar: Calendar
    ) -> [MenstrualRecord] {
        records.filter { record in
            guard let endDate = record.endDate else { return false }
            let start = calendar.startOfDay(for: record.startDate)
            let end = calendar.startOfDay(for: endDate)
            guard end >= start else { return false }
            guard let dayCount = record.dayCount(calendar: calendar),
                  config.validPeriodRange.contains(dayCount) else { return false }
            return true
        }
    }

    // MARK: - Step 3a: Make Period Samples

    func makePeriodSamples(
        from records: [MenstrualRecord],
        calendar: Calendar
    ) -> [PeriodSample] {
        records.compactMap { record in
            guard let dayCount = record.dayCount(calendar: calendar) else { return nil }
            return PeriodSample(
                startDate: calendar.startOfDay(for: record.startDate),
                periodLength: dayCount
            )
        }
    }

    // MARK: - Step 3b: Make Cycle Samples

    func makeCycleSamples(
        from records: [MenstrualRecord],
        calendar: Calendar
    ) -> [CycleSample] {
        guard records.count >= 2 else { return [] }

        var samples: [CycleSample] = []
        for i in 1..<records.count {
            let prevStart = calendar.startOfDay(for: records[i - 1].startDate)
            let currStart = calendar.startOfDay(for: records[i].startDate)
            let days = calendar.dateComponents([.day], from: prevStart, to: currStart).day ?? 0

            guard config.validCycleRange.contains(days) else { continue }

            samples.append(CycleSample(
                startDate: currStart,
                cycleLength: days,
                weightFactor: 1.0
            ))
        }
        return samples
    }

    // MARK: - Step 4: Clean Cycle Samples

    func cleanCycleSamples(_ samples: [CycleSample]) -> [CycleSample] {
        guard samples.count >= 3 else {
            return samples
        }

        let lengths = samples.map(\.cycleLength).sorted()
        let cycleMedian = Self.median(lengths)

        return samples.map { sample in
            let deviation = abs(Double(sample.cycleLength) - cycleMedian)
            let weight: Double
            if deviation <= config.outlierNormalThreshold {
                weight = 1.0
            } else if deviation <= config.outlierMildThreshold {
                weight = config.outlierMildWeight
            } else {
                weight = config.outlierSevereWeight
            }
            return CycleSample(
                startDate: sample.startDate,
                cycleLength: sample.cycleLength,
                weightFactor: weight
            )
        }
    }

    // MARK: - Step 5: Classify Variability

    func classifyVariability(from cycles: [Int]) -> CycleVariability {
        let recent = Array(cycles.suffix(6))
        guard let maxVal = recent.max(), let minVal = recent.min() else {
            return .moderate
        }
        let range = maxVal - minVal
        if range <= config.variabilityRegularMaxRange {
            return .regular
        } else if range <= config.variabilityModerateMaxRange {
            return .moderate
        } else {
            return .irregular
        }
    }

    // MARK: - Step 6: Detect Shift

    func detectShift(from cycles: [Int]) -> Bool {
        guard cycles.count >= 6 else { return false }

        let recent3 = Array(cycles.suffix(3))
        let previousCount = min(cycles.count - 3, 6)
        let previous = Array(cycles.suffix(3 + previousCount).prefix(previousCount))

        guard !previous.isEmpty else { return false }

        let recentMedian = Self.median(recent3.sorted())
        let previousMedian = Self.median(previous.sorted())

        return abs(recentMedian - previousMedian) >= config.shiftThreshold
    }

    // MARK: - Step 7: Predict Cycle Length

    func predictCycleLength(
        from cleanCycles: [CycleSample]
    ) -> (value: Int?, detectedShift: Bool) {
        guard !cleanCycles.isEmpty else { return (nil, false) }

        let cycleLengths = cleanCycles.map(\.cycleLength)

        // Case 2: cycle 1개
        if cleanCycles.count == 1 {
            return (cycleLengths[0], false)
        }

        // Case 3: cycle 2개
        if cleanCycles.count == 2 {
            let med = Self.median(cycleLengths.sorted())
            return (Int(med.rounded()), false)
        }

        // Case 4: cycle 3~4개 (축소 adaptive)
        if cleanCycles.count <= 4 {
            let variability = classifyVariability(from: cycleLengths)
            let alpha = ewmaAlpha(for: variability)
            let shortTerm = Self.ewma(values: cleanCycles, alpha: alpha)
            let longTerm = Self.median(cycleLengths.sorted())
            let shortWeight = config.cycleWeightReduced
            let pred = shortWeight * shortTerm + (1 - shortWeight) * longTerm
            return (Int(pred.rounded()), false)
        }

        // Case 5: cycle 5개 이상 → full v1.5
        let variability = classifyVariability(from: cycleLengths)
        let shift = detectShift(from: cycleLengths)

        // short-term: 최근 3~6개
        let shortTermCount = min(cleanCycles.count, 6)
        let shortTermSamples = Array(cleanCycles.suffix(shortTermCount))
        let alpha = ewmaAlpha(for: variability)
        let shortTermCycle = Self.ewma(values: shortTermSamples, alpha: alpha)

        // long-term: 최근 8~12개 중앙값
        let longTermCount = min(cleanCycles.count, 12)
        let longTermSamples = Array(cleanCycles.suffix(longTermCount))
        let longTermCycle = Self.median(longTermSamples.map(\.cycleLength).sorted())

        let shortWeight: Double
        if shift {
            shortWeight = config.cycleWeightShift
        } else {
            switch variability {
            case .regular:   shortWeight = config.cycleWeightRegular
            case .moderate:  shortWeight = config.cycleWeightModerate
            case .irregular: shortWeight = config.cycleWeightIrregular
            }
        }
        let pred = shortWeight * shortTermCycle + (1 - shortWeight) * longTermCycle

        return (Int(pred.rounded()), shift)
    }

    // MARK: - Step 8: Predict Period Length

    func predictPeriodLength(
        from periods: [PeriodSample],
        variability: CycleVariability?
    ) -> Int? {
        guard !periods.isEmpty else { return nil }

        let lengths = periods.map(\.periodLength)

        // 6개 이하면 단순 중앙값
        guard periods.count >= 6, let variability else {
            let count = min(periods.count, 6)
            let recent = Array(lengths.suffix(count)).sorted()
            return Int(Self.median(recent).rounded())
        }

        // short-term: 최근 3개 중앙값
        let shortTermPeriod = Self.median(Array(lengths.suffix(3)).sorted())

        // long-term: 최근 6~12개 중앙값
        let longTermCount = min(periods.count, 12)
        let longTermPeriod = Self.median(Array(lengths.suffix(longTermCount)).sorted())

        let shortWeight: Double
        switch variability {
        case .regular, .moderate:
            shortWeight = config.periodWeightStable
        case .irregular:
            shortWeight = config.periodWeightIrregular
        }
        let pred = shortWeight * shortTermPeriod + (1 - shortWeight) * longTermPeriod

        return max(1, Int(pred.rounded()))
    }

    // MARK: - Step 9: Build Menstrual Predictions

    /// 마지막 실제 월경 시작일 기준으로 최대 count개의 다음 월경 예측 레코드를 생성한다.
    static func buildMenstrualPredictions(
        from lastStartDay: Date,
        cycleLength: Int,
        periodLength: Int,
        count: Int,
        calendar: Calendar
    ) -> [MenstrualRecord] {
        var predictions: [MenstrualRecord] = []
        var anchor = lastStartDay

        for _ in 0..<count {
            guard let predictedStart = calendar.date(byAdding: .day, value: cycleLength, to: anchor),
                  let predictedEnd = calendar.date(byAdding: .day, value: periodLength - 1, to: predictedStart)
            else { break }

            predictions.append(MenstrualRecord(
                type: .menstrualPrediction,
                startDate: predictedStart,
                endDate: predictedEnd
            ))

            anchor = predictedStart
        }

        return predictions
    }

    // MARK: - Confidence

    func determineConfidence(
        cleanCycleCount: Int,
        variability: CycleVariability?,
        shift: Bool
    ) -> PredictionConfidence {
        if cleanCycleCount <= 0 {
            return .insufficient
        }

        if cleanCycleCount <= 2 {
            return .low
        }

        if let variability, variability == .irregular {
            return .low
        }

        if cleanCycleCount >= 6 {
            if let variability, variability == .regular, !shift {
                return .high
            }
            return .medium
        }

        // 3~5개
        return .medium
    }

    // MARK: - EWMA

    private func ewmaAlpha(for variability: CycleVariability) -> Double {
        switch variability {
        case .regular:   return config.ewmaAlphaRegular
        case .moderate:  return config.ewmaAlphaModerate
        case .irregular: return config.ewmaAlphaIrregular
        }
    }

    private func blendCycleLength(_ predicted: Int?, with userInput: Int?) -> Int? {
        blendLength(
            predicted,
            userInput: userInput,
            validRange: config.validCycleRange,
            blendWeight: config.userInputCycleBlendWeight
        )
    }

    private func blendPeriodLength(_ predicted: Int?, with userInput: Int?) -> Int? {
        blendLength(
            predicted,
            userInput: userInput,
            validRange: config.validPeriodRange,
            blendWeight: config.userInputPeriodBlendWeight
        )
    }

    private func blendLength(
        _ predicted: Int?,
        userInput: Int?,
        validRange: ClosedRange<Int>,
        blendWeight: Double
    ) -> Int? {
        let normalizedUserInput = userInput.flatMap { validRange.contains($0) ? $0 : nil }

        switch (predicted, normalizedUserInput) {
        case let (predicted?, userInput?):
            let clampedWeight = min(max(blendWeight, 0), 1)
            let blendedValue = (1 - clampedWeight) * Double(predicted) + clampedWeight * Double(userInput)
            return Int(blendedValue.rounded())
        case let (predicted?, nil):
            return predicted
        case let (nil, userInput?):
            return userInput
        case (nil, nil):
            return nil
        }
    }

    /// 가중 EWMA: weightFactor를 반영한 지수 가중 이동 평균
    private static func ewma(values: [CycleSample], alpha: Double) -> Double {
        guard let first = values.first else { return 0 }

        var result = Double(first.cycleLength)

        for i in 1..<values.count {
            let sample = values[i]
            let effectiveAlpha = alpha * sample.weightFactor
            result = effectiveAlpha * Double(sample.cycleLength) + (1 - effectiveAlpha) * result
        }

        return result
    }

    // MARK: - Utilities

    /// 정렬된 배열의 중앙값 계산
    static func median(_ sorted: [Int]) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let count = sorted.count
        if count % 2 == 0 {
            return Double(sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
        } else {
            return Double(sorted[count / 2])
        }
    }
}
