//
//  CyclePredictionEngine.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//


// CyclePredictionEngine.swift

import Foundation

struct CyclePredictionEngine {
    
    struct Config {
        /// 예측에 사용할 최소 사이클 개수 (이보다 적으면 예측 안 함)
        let minimumCyclesForPrediction: Int
        /// 미래에 몇 주기까지 예측할지
        let numberOfFutureCycles: Int
        
        static let `default` = Config(
            minimumCyclesForPrediction: 2,
            numberOfFutureCycles: 3
        )
    }

    let config: Config
    
    init(config: Config = .default) {
        self.config = config
    }
    
    struct PredictionParameters {
        let avgCycleLength: Double     // 평균 사이클 길이 (일 단위)
        let avgPeriodLength: Double    // 평균 월경 기간 (일 단위)
    }
    
    // MARK: - Public
    
    func makePredictions(from records: [CycleRecord]) -> [CycleRecord] {
        let calendar = Calendar.current
        
        // 1) 데이터 정리: 월경 기록만 추출 + 정렬
        let menstrualRecords = extractMenstrualRecords(from: records)
        
        // 마지막 월경 시작일 (예측 anchor)
        guard let lastRecord = menstrualRecords.last else { return [] }
        let lastStart = calendar.startOfDay(for: lastRecord.startDate)
        
        // 2) 예측에 사용할 "숫자 값" 계산 (예측 파라미터)
        guard let params = makePredictionParameters(from: menstrualRecords) else {
            return []
        }
        
        // 3) 숫자 값 + lastStart 을 이용해서 실제 .menstrualPrediction 레코드 생성
        return buildPredictions(
            from: params,
            lastStart: lastStart
        )
    }
    
    func mergingPredictions(with records: [CycleRecord]) -> [CycleRecord] {
        let predictions = makePredictions(from: records)
        return (records + predictions).sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - 1) 데이터 정리
    
    /// records에서 .menstrualRecord만 뽑고, 시작일 기준으로 정렬
    private func extractMenstrualRecords(from records: [CycleRecord]) -> [CycleRecord] {
        records
            .filter { $0.type == .menstrualRecord }
            .sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - 2) 예측 파라미터 계산 (여기가 "주기 예측 로직" 부분)
    
    /// 정리된 월경 기록들로부터
    /// - 평균 사이클 길이
    /// - 평균 월경 길이
    /// 를 계산해서 PredictionParameters로 반환
    private func makePredictionParameters(from menstrualRecords: [CycleRecord]) -> PredictionParameters? {
        let calendar = Calendar.current
        
        // 사이클 길이를 계산하려면 최소 (N+1)개의 월경 기록이 필요
        guard menstrualRecords.count >= config.minimumCyclesForPrediction + 1 else {
            return nil
        }
        
        // 2-1) 사이클 길이(시작일 사이 간격) 리스트 만들기
        let cycleLengths = makeCycleLengths(
            from: menstrualRecords,
            calendar: calendar
        )
        
        // 최소 N개의 유효 사이클 길이가 있어야 함
        guard cycleLengths.count >= config.minimumCyclesForPrediction else {
            return nil
        }
        
        // 최근 N개 사이클만 사용해서 평균 사이클 길이 계산
        let recentCycleLengths = Array(cycleLengths.suffix(config.minimumCyclesForPrediction))
        let avgCycleLength = average(of: recentCycleLengths)
        
        // 2-2) 월경 기간(각 record의 일수) 리스트에서 최근 N개의 평균
        let allPeriodLengths = menstrualRecords.map { $0.dayCount }
        let recentPeriodLengths = Array(allPeriodLengths.suffix(config.minimumCyclesForPrediction))
        let avgPeriodLength = average(of: recentPeriodLengths)
        
        return PredictionParameters(
            avgCycleLength: avgCycleLength,
            avgPeriodLength: avgPeriodLength
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
