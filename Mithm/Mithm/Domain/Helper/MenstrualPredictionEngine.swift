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

        // MARK: 시간 가중치 (recency weighting)

        /// 시간 가중치 감소 곡선의 기준 일수 (작을수록 최근 기록에 민감)
        let recencyDecayDays: Double
        /// 오래된 기록의 최소 가중치 (0이 되지 않도록)
        let recencyMinimumWeight: Double

        // MARK: 사용자 입력 blend 제어

        /// 사용자 입력 blend 사용 여부 (false이면 모델 예측만 사용)
        let shouldBlendUserInput: Bool

        // MARK: Adaptive blend 비율 — cycle length

        /// 기록 0...2개일 때 사용자 입력 cycle blend weight
        let userInputCycleWeightVeryLowHistory: Double
        /// 기록 3...5개일 때 사용자 입력 cycle blend weight
        let userInputCycleWeightLowHistory: Double
        /// 기록 6개 이상일 때 사용자 입력 cycle blend weight
        let userInputCycleWeightHighHistory: Double
        /// confidence == .high 일 때 cycle blend weight override
        let userInputCycleWeightHighConfidenceOverride: Double

        // MARK: Adaptive blend 비율 — period length

        /// 기록 0...2개일 때 사용자 입력 period blend weight
        let userInputPeriodWeightVeryLowHistory: Double
        /// 기록 3...5개일 때 사용자 입력 period blend weight
        let userInputPeriodWeightLowHistory: Double
        /// 기록 6개 이상일 때 사용자 입력 period blend weight
        let userInputPeriodWeightHighHistory: Double

        // MARK: Shift 감지

        /// 최근 3개 vs 이전 3~6개 중앙값 차이 임계값
        let shiftThreshold: Double

        // MARK: 예측 개수

        /// 앞으로 생성할 월경 예측 레코드 수
        let predictionCount: Int

        // MARK: Default

        static let `default` = Config(
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

            recencyDecayDays: 180,
            recencyMinimumWeight: 0.25,

            shouldBlendUserInput: true,

            userInputCycleWeightVeryLowHistory: 0.30,
            userInputCycleWeightLowHistory: 0.15,
            userInputCycleWeightHighHistory: 0.08,
            userInputCycleWeightHighConfidenceOverride: 0.03,

            userInputPeriodWeightVeryLowHistory: 0.30,
            userInputPeriodWeightLowHistory: 0.20,
            userInputPeriodWeightHighHistory: 0.12,

            shiftThreshold: 4.0,
            predictionCount: 3
        )
    }

    let config: Config

    init(
        config: Config = .default,
        shouldBlendUserInput: Bool? = nil
    ) {
        if let shouldBlendUserInput {
            self.config = Self.makeConfig(
                from: config,
                shouldBlendUserInput: shouldBlendUserInput
            )
        } else {
            self.config = config
        }
    }

    // MARK: - Public

    func predict(
        from records: [MenstrualRecord],
        userInput: MenstrualUserInput? = nil,
        calendar: Calendar = .current
    ) -> MenstrualPredictionResult {
        let effectiveUserInput = config.shouldBlendUserInput ? userInput : nil
        let actualRecords = Self.extractActualRecords(from: records)
        let validRecords = validateRecords(actualRecords, calendar: calendar)
        let recordCount = validRecords.count
        let lastValidStartDay = validRecords.last.map { calendar.startOfDay(for: $0.startDate) }

        guard !validRecords.isEmpty else {
            return predictWithUserInputOnly(effectiveUserInput, calendar: calendar)
        }

        let periodSamples = makePeriodSamples(from: validRecords, calendar: calendar)
        let rawCycleSamples = makeCycleSamples(from: validRecords, calendar: calendar)
        let cleanCycles = cleanCycleSamples(rawCycleSamples)

        if recordCount == 1 {
            return predictFromSingleRecord(
                periodSamples: periodSamples,
                userInput: effectiveUserInput,
                lastStartDay: lastValidStartDay,
                usedRecordCount: recordCount,
                calendar: calendar
            )
        }

        let variability = classifyVariabilityIfPossible(from: cleanCycles)
        let (predCycle, shift) = predictCycleLength(from: cleanCycles, calendar: calendar)
        let predPeriod = predictPeriodLength(from: periodSamples, variability: variability)
        let confidence = determineConfidence(
            cleanCycleCount: cleanCycles.count,
            variability: variability,
            shift: shift
        )
        let blendedLengths = blendPredictedLengths(
            predictedCycle: predCycle,
            predictedPeriod: predPeriod,
            userInput: effectiveUserInput,
            cleanCycleCount: cleanCycles.count,
            periodSampleCount: periodSamples.count,
            confidence: confidence
        )

        guard let cycleLen = blendedLengths.cycle, let periodLen = blendedLengths.period else {
            return makeResult(
                menstrualPredictions: [],
                predictedCycleLength: blendedLengths.cycle,
                predictedPeriodLength: blendedLengths.period,
                confidence: .low,
                usedRecordCount: recordCount,
                detectedShift: shift,
                usedDefaultRule: false
            )
        }

        let predictions = buildPredictions(
            from: lastValidStartDay,
            cycleLength: cycleLen,
            periodLength: periodLen,
            calendar: calendar
        )

        return makeResult(
            menstrualPredictions: predictions,
            predictedCycleLength: cycleLen,
            predictedPeriodLength: periodLen,
            confidence: confidence,
            usedRecordCount: recordCount,
            detectedShift: shift,
            usedDefaultRule: false
        )
    }

    private func predictWithUserInputOnly(
        _ userInput: MenstrualUserInput?,
        calendar: Calendar
    ) -> MenstrualPredictionResult {
        guard let userInput,
              let cycleLength = normalizedLength(userInput.cycleLength, validRange: config.validCycleRange),
              let periodLength = normalizedLength(userInput.periodLength, validRange: config.validPeriodRange)
        else {
            return makeResult(
                menstrualPredictions: [],
                predictedCycleLength: nil,
                predictedPeriodLength: nil,
                confidence: .insufficient,
                usedRecordCount: 0,
                detectedShift: false,
                usedDefaultRule: false
            )
        }

        let predictions = Self.buildMenstrualPredictions(
            from: calendar.startOfDay(for: Date()),
            cycleLength: cycleLength,
            periodLength: periodLength,
            count: config.predictionCount,
            calendar: calendar
        )

        return makeResult(
            menstrualPredictions: predictions,
            predictedCycleLength: cycleLength,
            predictedPeriodLength: periodLength,
            confidence: .low,
            usedRecordCount: 0,
            detectedShift: false,
            usedDefaultRule: false
        )
    }

    private func predictFromSingleRecord(
        periodSamples: [PeriodSample],
        userInput: MenstrualUserInput?,
        lastStartDay: Date?,
        usedRecordCount: Int,
        calendar: Calendar
    ) -> MenstrualPredictionResult {
        let actualPeriodLength = periodSamples.last?.periodLength

        guard let userInput,
              let cycleLength = normalizedLength(userInput.cycleLength, validRange: config.validCycleRange)
        else {
            return makeResult(
                menstrualPredictions: [],
                predictedCycleLength: nil,
                predictedPeriodLength: actualPeriodLength,
                confidence: .insufficient,
                usedRecordCount: usedRecordCount,
                detectedShift: false,
                usedDefaultRule: false
            )
        }

        guard let periodLength = resolvedSingleRecordPeriodLength(
            actualPeriodLength: actualPeriodLength,
            userInputPeriodLength: userInput.periodLength
        ) else {
            return makeResult(
                menstrualPredictions: [],
                predictedCycleLength: cycleLength,
                predictedPeriodLength: nil,
                confidence: .insufficient,
                usedRecordCount: usedRecordCount,
                detectedShift: false,
                usedDefaultRule: false
            )
        }

        let predictions = buildPredictions(
            from: lastStartDay,
            cycleLength: cycleLength,
            periodLength: periodLength,
            calendar: calendar
        )

        return makeResult(
            menstrualPredictions: predictions,
            predictedCycleLength: cycleLength,
            predictedPeriodLength: periodLength,
            confidence: .low,
            usedRecordCount: usedRecordCount,
            detectedShift: false,
            usedDefaultRule: false
        )
    }

    private func classifyVariabilityIfPossible(from cleanCycles: [CycleSample]) -> CycleVariability? {
        let variabilityCycles = variabilityCycleLengths(from: cleanCycles)
        guard variabilityCycles.count >= 2 else { return nil }
        return classifyVariability(from: variabilityCycles)
    }

    private func blendPredictedLengths(
        predictedCycle: Int?,
        predictedPeriod: Int?,
        userInput: MenstrualUserInput?,
        cleanCycleCount: Int,
        periodSampleCount: Int,
        confidence: PredictionConfidence
    ) -> (cycle: Int?, period: Int?) {
        guard let userInput else {
            return (predictedCycle, predictedPeriod)
        }

        let cycle = blendLength(
            predictedCycle,
            userInput: userInput.cycleLength,
            validRange: config.validCycleRange,
            blendWeight: adaptiveCycleBlendWeight(
                usedRecordCount: cleanCycleCount,
                confidence: confidence
            )
        )
        let period = blendLength(
            predictedPeriod,
            userInput: userInput.periodLength,
            validRange: config.validPeriodRange,
            blendWeight: adaptivePeriodBlendWeight(usedRecordCount: periodSampleCount)
        )

        return (cycle, period)
    }

    private func resolvedSingleRecordPeriodLength(
        actualPeriodLength: Int?,
        userInputPeriodLength: Int?
    ) -> Int? {
        let normalizedUserPeriod = normalizedLength(
            userInputPeriodLength,
            validRange: config.validPeriodRange
        )

        switch (actualPeriodLength, normalizedUserPeriod) {
        case let (actual?, userPeriod?):
            let blendWeight = config.userInputPeriodWeightVeryLowHistory
            let blendedPeriod = (1 - blendWeight) * Double(actual) + blendWeight * Double(userPeriod)
            return Int(blendedPeriod.rounded())
        case let (actual?, nil):
            return actual
        case let (nil, userPeriod?):
            return userPeriod
        case (nil, nil):
            return nil
        }
    }

    private func buildPredictions(
        from anchorDate: Date?,
        cycleLength: Int,
        periodLength: Int,
        calendar: Calendar
    ) -> [MenstrualRecord] {
        guard let anchorDate else { return [] }

        return Self.buildMenstrualPredictions(
            from: anchorDate,
            cycleLength: cycleLength,
            periodLength: periodLength,
            count: config.predictionCount,
            calendar: calendar
        )
    }

    private func normalizedLength(
        _ value: Int?,
        validRange: ClosedRange<Int>
    ) -> Int? {
        guard let value, validRange.contains(value) else { return nil }
        return value
    }

    private func makeResult(
        menstrualPredictions: [MenstrualRecord],
        predictedCycleLength: Int?,
        predictedPeriodLength: Int?,
        confidence: PredictionConfidence,
        usedRecordCount: Int,
        detectedShift: Bool,
        usedDefaultRule: Bool
    ) -> MenstrualPredictionResult {
        MenstrualPredictionResult(
            menstrualPredictions: menstrualPredictions,
            predictedCycleLength: predictedCycleLength,
            predictedPeriodLength: predictedPeriodLength,
            confidence: confidence,
            usedRecordCount: usedRecordCount,
            detectedShift: detectedShift,
            usedDefaultRule: usedDefaultRule
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

    // MARK: - Step 4b: Variability용 Cycle Lengths (severe outlier 제외)

    /// severe outlier를 제외한 cycle length 배열을 반환한다.
    /// variability 분류 전용으로 사용하여 극단적 이상치에 의한 왜곡을 방지한다.
    func variabilityCycleLengths(from cleanCycles: [CycleSample]) -> [Int] {
        let nonSevere = cleanCycles
            .filter { $0.weightFactor > config.outlierSevereWeight }
            .map(\.cycleLength)

        // severe 제외 후 2개 이상이면 사용, 아니면 전체 fallback
        if nonSevere.count >= 2 {
            return nonSevere
        }
        return cleanCycles.map(\.cycleLength)
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
        from cleanCycles: [CycleSample],
        calendar: Calendar = .current
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

        // variability 분류 — severe outlier 제외
        let variabilityCycles = variabilityCycleLengths(from: cleanCycles)

        // Case 4: cycle 3~4개 (축소 adaptive)
        if cleanCycles.count <= 4 {
            let variability = classifyVariability(from: variabilityCycles)
            let alpha = ewmaAlpha(for: variability)
            let shortTerm = Self.ewma(values: cleanCycles, alpha: alpha, calendar: calendar, config: config)
            let longTerm = Self.median(cycleLengths.sorted())
            let shortWeight = config.cycleWeightReduced
            let pred = shortWeight * shortTerm + (1 - shortWeight) * longTerm
            return (Int(pred.rounded()), false)
        }

        // Case 5: cycle 5개 이상 → full v1.5
        let variability = classifyVariability(from: variabilityCycles)
        let shift = detectShift(from: cycleLengths)

        // short-term: 최근 3~6개
        let shortTermCount = min(cleanCycles.count, 6)
        let shortTermSamples = Array(cleanCycles.suffix(shortTermCount))
        let alpha = ewmaAlpha(for: variability)
        let shortTermCycle = Self.ewma(values: shortTermSamples, alpha: alpha, calendar: calendar, config: config)

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

    // MARK: - Recency Weight

    /// 날짜 기반 시간 가중치를 계산한다.
    /// 가장 최근 cycle은 1.0, 오래될수록 감소하며, 최소 recencyMinimumWeight 이상을 보장한다.
    func recencyWeight(
        for sampleDate: Date,
        latestDate: Date,
        calendar: Calendar
    ) -> Double {
        let days = calendar.dateComponents([.day], from: sampleDate, to: latestDate).day ?? 0
        guard days > 0 else { return 1.0 }
        let decay = exp(-Double(days) / config.recencyDecayDays)
        return max(config.recencyMinimumWeight, decay)
    }

    // MARK: - Adaptive Blend Weights

    /// 기록 수와 confidence에 따른 adaptive cycle blend weight
    func adaptiveCycleBlendWeight(
        usedRecordCount: Int,
        confidence: PredictionConfidence
    ) -> Double {
        if confidence == .high {
            return config.userInputCycleWeightHighConfidenceOverride
        }

        switch usedRecordCount {
        case 0...2:
            return config.userInputCycleWeightVeryLowHistory
        case 3...5:
            return config.userInputCycleWeightLowHistory
        default:
            return config.userInputCycleWeightHighHistory
        }
    }

    /// 기록 수에 따른 adaptive period blend weight
    func adaptivePeriodBlendWeight(usedRecordCount: Int) -> Double {
        switch usedRecordCount {
        case 0...2:
            return config.userInputPeriodWeightVeryLowHistory
        case 3...5:
            return config.userInputPeriodWeightLowHistory
        default:
            return config.userInputPeriodWeightHighHistory
        }
    }

    // MARK: - EWMA

    private func ewmaAlpha(for variability: CycleVariability) -> Double {
        switch variability {
        case .regular:   return config.ewmaAlphaRegular
        case .moderate:  return config.ewmaAlphaModerate
        case .irregular: return config.ewmaAlphaIrregular
        }
    }

    private func blendLength(
        _ predicted: Int?,
        userInput: Int?,
        validRange: ClosedRange<Int>,
        blendWeight: Double
    ) -> Int? {
        let normalizedUserInput = normalizedLength(userInput, validRange: validRange)

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

    /// 가중 EWMA: weightFactor와 recency weight를 반영한 지수 가중 이동 평균.
    /// 초기값은 median 기반으로 설정한다.
    private static func ewma(
        values: [CycleSample],
        alpha: Double,
        calendar: Calendar = .current,
        config: Config = .default
    ) -> Double {
        guard !values.isEmpty else { return 0 }

        // 초기값: median 기반
        let cycleLengths = values.map(\.cycleLength).sorted()
        var result = median(cycleLengths)

        // 최근 sample의 날짜 (recency weight 기준점)
        let latestDate = values.last!.startDate

        for sample in values {
            let recency = recencyWeight(
                for: sample.startDate,
                latestDate: latestDate,
                calendar: calendar,
                config: config
            )
            let effectiveAlpha = alpha * sample.weightFactor * recency
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

    private static func recencyWeight(
        for sampleDate: Date,
        latestDate: Date,
        calendar: Calendar,
        config: Config
    ) -> Double {
        let days = calendar.dateComponents([.day], from: sampleDate, to: latestDate).day ?? 0
        guard days > 0 else { return 1.0 }
        let decay = exp(-Double(days) / config.recencyDecayDays)
        return max(config.recencyMinimumWeight, decay)
    }

    private static func makeConfig(
        from config: Config,
        shouldBlendUserInput: Bool
    ) -> Config {
        Config(
            validPeriodRange: config.validPeriodRange,
            validCycleRange: config.validCycleRange,
            outlierNormalThreshold: config.outlierNormalThreshold,
            outlierMildThreshold: config.outlierMildThreshold,
            outlierMildWeight: config.outlierMildWeight,
            outlierSevereWeight: config.outlierSevereWeight,
            variabilityRegularMaxRange: config.variabilityRegularMaxRange,
            variabilityModerateMaxRange: config.variabilityModerateMaxRange,
            ewmaAlphaRegular: config.ewmaAlphaRegular,
            ewmaAlphaModerate: config.ewmaAlphaModerate,
            ewmaAlphaIrregular: config.ewmaAlphaIrregular,
            cycleWeightRegular: config.cycleWeightRegular,
            cycleWeightModerate: config.cycleWeightModerate,
            cycleWeightIrregular: config.cycleWeightIrregular,
            cycleWeightShift: config.cycleWeightShift,
            cycleWeightReduced: config.cycleWeightReduced,
            periodWeightStable: config.periodWeightStable,
            periodWeightIrregular: config.periodWeightIrregular,
            recencyDecayDays: config.recencyDecayDays,
            recencyMinimumWeight: config.recencyMinimumWeight,
            shouldBlendUserInput: shouldBlendUserInput,
            userInputCycleWeightVeryLowHistory: config.userInputCycleWeightVeryLowHistory,
            userInputCycleWeightLowHistory: config.userInputCycleWeightLowHistory,
            userInputCycleWeightHighHistory: config.userInputCycleWeightHighHistory,
            userInputCycleWeightHighConfidenceOverride: config.userInputCycleWeightHighConfidenceOverride,
            userInputPeriodWeightVeryLowHistory: config.userInputPeriodWeightVeryLowHistory,
            userInputPeriodWeightLowHistory: config.userInputPeriodWeightLowHistory,
            userInputPeriodWeightHighHistory: config.userInputPeriodWeightHighHistory,
            shiftThreshold: config.shiftThreshold,
            predictionCount: config.predictionCount
        )
    }
}
