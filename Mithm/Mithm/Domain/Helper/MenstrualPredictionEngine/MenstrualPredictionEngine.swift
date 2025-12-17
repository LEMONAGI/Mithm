//
//  MenstrualPredictionEngine.swift
//  Mithm
//
//  Created by YunhakLee on 12/17/25.
//


import Foundation

struct MenstrualPredictionEngine {

    // MARK: - Config

    struct Config {
        /// 예측에 사용할 최소 사이클 개수 (이보다 적으면 예측 안 함)
        let minimumCyclesForPrediction: Int
        /// 미래에 몇 주기까지 예측할지
        let numberOfFutureCycles: Int

        /// 사용자 입력(avgCycleLength / avgPeriodLength)에 줄 가중치 (0.0 ~ 1.0)
        /// 1.0  → 사용자 입력 100% 신뢰
        /// 0.0  → 기록 기반 값만 사용
        let userWeight: Double

        static let `default` = Config(
            minimumCyclesForPrediction: 2,
            numberOfFutureCycles: 3,
            userWeight: 0.5
        )
    }

    /// 사용자가 “내가 느끼는 평균 주기/기간”을 직접 입력한 값
    struct UserPreference {
        /// 사용자가 생각하는 평균 사이클 길이 (일 단위). nil이면 미입력.
        let avgCycleLength: Double?
        /// 사용자가 생각하는 평균 월경 기간 (일 단위). nil이면 미입력.
        let avgPeriodLength: Double?
    }

    struct PredictionParameters {
        let avgCycleLength: Double     // 최종 평균 사이클 길이 (일 단위)
        let avgPeriodLength: Double    // 최종 평균 월경 기간 (일 단위)
    }

    let config: Config

    init(config: Config = .default) {
        self.config = config
    }

    // MARK: - Public API

    /// 실제 기록 + (선택적으로) 사용자 입력을 기반으로 월경 예측 레코드를 만든다.
    func makePredictions(
        from records: [MenstrualRecord],
        userPreference: UserPreference? = nil
    ) -> [MenstrualRecord] {
        let calendar = Calendar.current

        // 1) 데이터 정리: 월경 "실제 기록"만 추출 + 정렬
        let menstrualRecords = extractMenstrualRecords(from: records)

        // 마지막 실제 월경 시작일 (예측 anchor)
        guard let lastRecord = menstrualRecords.last else { return [] }
        let lastStart = calendar.startOfDay(for: lastRecord.startDate)

        // 2) 예측에 사용할 숫자 값 계산 (기록 + 사용자 입력 블렌딩)
        guard let params = makePredictionParameters(
            from: menstrualRecords,
            userPreference: userPreference
        ) else {
            return []
        }

        // 3) 숫자 값 + lastStart로 미래 예측 레코드 생성
        return buildPredictions(from: params, lastStart: lastStart)
    }

    /// 기존 records에 예측 레코드를 합쳐서 타임라인 정렬한 버전 반환
    func mergingPredictions(
        with records: [MenstrualRecord],
        userPreference: UserPreference? = nil
    ) -> [MenstrualRecord] {
        let predictions = makePredictions(from: records, userPreference: userPreference)
        return (records + predictions).sorted { $0.startDate < $1.startDate }
    }

    // MARK: - 1) 데이터 정리

    /// records에서 "실제 월경 기록"만 뽑고 시작일 기준 정렬
    private func extractMenstrualRecords(from records: [MenstrualRecord]) -> [MenstrualRecord] {
        records
            .filter { $0.type == .menstrualRecord } // ✅ 네 도메인에 맞게 여기만 바꾸면 됨
            .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - 2) 예측 파라미터 계산

    private func makePredictionParameters(
        from menstrualRecords: [MenstrualRecord],
        userPreference: UserPreference?
    ) -> PredictionParameters? {

        let calendar = Calendar.current

        var estimatedCycleLength: Double?
        var estimatedPeriodLength: Double?

        // 사이클 길이 계산하려면 최소 (N+1)개의 "시작일"이 필요
        if menstrualRecords.count >= config.minimumCyclesForPrediction + 1 {
            let cycleLengths = makeCycleLengths(from: menstrualRecords, calendar: calendar)
            if cycleLengths.count >= config.minimumCyclesForPrediction {
                let recent = Array(cycleLengths.suffix(config.minimumCyclesForPrediction))
                estimatedCycleLength = average(of: recent)
            }
        }

        // 월경 기간 평균은 endDate 있는 기록만 사용
        let periodLengths = menstrualRecords.compactMap { $0.dayCount }
        if periodLengths.count >= config.minimumCyclesForPrediction {
            let recent = Array(periodLengths.suffix(config.minimumCyclesForPrediction))
            estimatedPeriodLength = average(of: recent)
        } else if !periodLengths.isEmpty {
            // 최소 조건이 안되면 "있는 만큼"으로라도 평균을 만들지,
            // 아니면 nil로 두고 사용자 입력에만 의존할지 정책 선택 가능.
            // 지금은 정책을 보수적으로: 있는 만큼 평균 허용.
            estimatedPeriodLength = average(of: periodLengths)
        }

        let userCycle = userPreference?.avgCycleLength
        let userPeriod = userPreference?.avgPeriodLength

        guard
            let finalCycle = blend(user: userCycle, estimated: estimatedCycleLength, userWeight: config.userWeight),
            let finalPeriod = blend(user: userPeriod, estimated: estimatedPeriodLength, userWeight: config.userWeight)
        else {
            return nil
        }

        return PredictionParameters(avgCycleLength: finalCycle, avgPeriodLength: finalPeriod)
    }

    private func makeCycleLengths(
        from menstrualRecords: [MenstrualRecord],
        calendar: Calendar
    ) -> [Int] {
        var lengths: [Int] = []

        for (before, after) in zip(menstrualRecords, menstrualRecords.dropFirst()) {
            let s1 = calendar.startOfDay(for: before.startDate)
            let s2 = calendar.startOfDay(for: after.startDate)
            let diff = calendar.dateComponents([.day], from: s1, to: s2).day ?? 0
            if diff > 0 { lengths.append(diff) }
        }

        return lengths
    }

    private func average(of values: [Int]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sum = values.reduce(0, +)
        return Double(sum) / Double(values.count)
    }

    private func blend(
        user: Double?,
        estimated: Double?,
        userWeight: Double
    ) -> Double? {
        switch (user, estimated) {
        case (nil, nil): return nil
        case (let u?, nil): return u
        case (nil, let e?): return e
        case (let u?, let e?):
            let w = min(max(userWeight, 0.0), 1.0)
            return w * u + (1.0 - w) * e
        }
    }

    // MARK: - 3) PredictionParameters → MenstrualRecord 생성

    private func buildPredictions(
        from params: PredictionParameters,
        lastStart: Date
    ) -> [MenstrualRecord] {

        let calendar = Calendar.current
        var predictions: [MenstrualRecord] = []

        for i in 1...config.numberOfFutureCycles {
            let dayOffset = Int(round(params.avgCycleLength * Double(i)))
            guard let predictedStart = calendar.date(byAdding: .day, value: dayOffset, to: lastStart) else { continue }

            let periodLengthInt = max(1, Int(round(params.avgPeriodLength)))
            guard let predictedEnd = calendar.date(byAdding: .day, value: periodLengthInt - 1, to: predictedStart) else { continue }

            predictions.append(
                MenstrualRecord(
                    type: .menstrualPrediction,
                    startDate: predictedStart,
                    endDate: predictedEnd
                )
            )
        }

        return predictions
    }
}
