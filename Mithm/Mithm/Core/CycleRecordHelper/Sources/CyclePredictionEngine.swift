//
//  CyclePredictionEngine.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation

struct CyclePredictionEngine {
    
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
    struct UserCyclePreference {
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
    
    /// 기록 + (선택적으로) 사용자 입력을 기반으로 월경 예측 레코드를 만든다.
    func makePredictions(
        from records: [CycleRecord],
        userPreference: UserCyclePreference? = nil
    ) -> [CycleRecord] {
        let calendar = Calendar.current
        
        // 1) 데이터 정리: 월경 기록만 추출 + 정렬
        let menstrualRecords = extractMenstrualRecords(from: records)
        
        // 마지막 월경 시작일 (예측 anchor)
        guard let lastRecord = menstrualRecords.last else { return [] }
        let lastStart = calendar.startOfDay(for: lastRecord.startDate)
        
        // 2) 예측에 사용할 "숫자 값" 계산 (기록 + 사용자 입력 블렌딩)
        guard let params = makePredictionParameters(
            from: menstrualRecords,
            userPreference: userPreference
        ) else {
            return []
        }
        
        // 3) 숫자 값 + lastStart 를 이용해서 실제 .menstrualPrediction 레코드 생성
        return buildPredictions(
            from: params,
            lastStart: lastStart
        )
    }
    
    /// 기존 records에 예측 레코드를 합쳐서 타임라인 정렬한 버전 반환
    func mergingPredictions(
        with records: [CycleRecord],
        userPreference: UserCyclePreference? = nil
    ) -> [CycleRecord] {
        let predictions = makePredictions(from: records, userPreference: userPreference)
        return (records + predictions).sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - 1) 데이터 정리
    
    /// records에서 .menstrualRecord만 뽑고, 시작일 기준으로 정렬
    private func extractMenstrualRecords(from records: [CycleRecord]) -> [CycleRecord] {
        records
            .filter { $0.type == .menstrualRecord }
            .sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - 2) 예측 파라미터 계산 (여기가 "주기 예측 로직" 핵심)
    
    /// 정리된 월경 기록들 + 사용자 입력으로부터
    /// - 평균 사이클 길이
    /// - 평균 월경 길이
    /// 를 계산해서 PredictionParameters로 반환
    private func makePredictionParameters(
        from menstrualRecords: [CycleRecord],
        userPreference: UserCyclePreference?
    ) -> PredictionParameters? {
        let calendar = Calendar.current
        
        // 기록 기반 추정값
        var estimatedCycleLength: Double?
        var estimatedPeriodLength: Double?
        
        // 사이클 길이를 계산하려면 최소 (N+1)개의 월경 기록이 필요
        if menstrualRecords.count >= config.minimumCyclesForPrediction + 1 {
            // 2-1) 사이클 길이(시작일 사이 간격) 리스트 만들기
            let cycleLengths = makeCycleLengths(
                from: menstrualRecords,
                calendar: calendar
            )
            
            // 최소 N개의 유효 사이클 길이가 있어야 함
            if cycleLengths.count >= config.minimumCyclesForPrediction {
                let recentCycleLengths = Array(cycleLengths.suffix(config.minimumCyclesForPrediction))
                estimatedCycleLength = average(of: recentCycleLengths)
            }
            
            // 2-2) 월경 기간(각 record의 일수) 리스트에서 최근 N개의 평균
            let allPeriodLengths = menstrualRecords.map { $0.dayCount }
            let recentPeriodLengths = Array(allPeriodLengths.suffix(config.minimumCyclesForPrediction))
            estimatedPeriodLength = average(of: recentPeriodLengths)
        }
        
        // 사용자 입력
        let userCycle = userPreference?.avgCycleLength
        let userPeriod = userPreference?.avgPeriodLength
        
        // 기록 기반 값 + 사용자 입력을 가중 평균으로 블렌딩
        guard
            let finalCycle = blend(
                user: userCycle,
                estimated: estimatedCycleLength,
                userWeight: config.userWeight
            ),
            let finalPeriod = blend(
                user: userPeriod,
                estimated: estimatedPeriodLength,
                userWeight: config.userWeight
            )
        else {
            // 기록도 없고 사용자 입력도 없어서 어느 쪽도 계산 불가한 경우
            return nil
        }
        
        return PredictionParameters(
            avgCycleLength: finalCycle,
            avgPeriodLength: finalPeriod
        )
    }
    
    /// 연속된 월경 기록들에서 "사이클 길이(시작일 사이 일수)" 리스트를 만든다.
    private func makeCycleLengths(
        from menstrualRecords: [CycleRecord],
        calendar: Calendar
    ) -> [Int] {
        var cycleLengths: [Int] = []
        
        for (before, after) in zip(menstrualRecords, menstrualRecords.dropFirst()) {
            let s1 = calendar.startOfDay(for: before.startDate)
            let s2 = calendar.startOfDay(for: after.startDate)
            let diff = calendar.dateComponents([.day], from: s1, to: s2).day ?? 0
            if diff > 0 {
                cycleLengths.append(diff)
            }
        }
        
        return cycleLengths
    }
    
    /// Int 배열의 평균을 Double로 계산하는 유틸
    private func average(of values: [Int]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sum = values.reduce(0, +)
        return Double(sum) / Double(values.count)
    }
    
    /// 사용자 입력 값과 기록 기반 추정값을 섞는다.
    ///
    /// - user == nil      → 사용자 입력 없음
    /// - estimated == nil → 기록 기반 추정값 없음
    /// - 둘 다 nil        → nil 반환
    /// - 둘 다 있음       → userWeight 비율로 가중 평균
    private func blend(
        user: Double?,
        estimated: Double?,
        userWeight: Double
    ) -> Double? {
        switch (user, estimated) {
        case (nil, nil):
            return nil
        case (let u?, nil):
            return u
        case (nil, let e?):
            return e
        case (let u?, let e?):
            let w = min(max(userWeight, 0.0), 1.0)
            return w * u + (1.0 - w) * e
        }
    }
    
    // MARK: - 3) 예측 파라미터 → CycleRecord 생성
    
    /// 예측 파라미터(평균 주기/평균 기간) + 마지막 시작일을 바탕으로
    /// 미래 .menstrualPrediction 레코드를 생성
    private func buildPredictions(
        from params: PredictionParameters,
        lastStart: Date
    ) -> [CycleRecord] {
        let calendar = Calendar.current
        
        var predictions: [CycleRecord] = []
        
        for i in 1...config.numberOfFutureCycles {
            // 예: 마지막 시작일 + avgCycleLength * i
            let dayOffset = Int(round(params.avgCycleLength * Double(i)))
            guard let predictedStart = calendar.date(byAdding: .day, value: dayOffset, to: lastStart) else {
                continue
            }
            
            let periodLengthInt = max(1, Int(round(params.avgPeriodLength)))
            guard let predictedEnd = calendar.date(byAdding: .day, value: periodLengthInt - 1, to: predictedStart) else {
                continue
            }
            
            let prediction = CycleRecord(
                type: .menstrualPrediction,
                startDate: predictedStart,
                endDate: predictedEnd
            )
            predictions.append(prediction)
        }
        
        return predictions
    }
}
