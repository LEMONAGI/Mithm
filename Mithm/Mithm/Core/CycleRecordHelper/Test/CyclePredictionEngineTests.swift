//
//  CyclePredictionEngineTests.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import XCTest
@testable import Mithm

final class CyclePredictionEngineTests: XCTestCase {
    
    private var calendar: Calendar!
    private var baseDate: Date!
    
    override func setUp() {
        super.setUp()
        calendar = Calendar.current
        
        // 고정된 기준 날짜 (예: 2025-01-01 00:00)
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        baseDate = calendar.date(from: components)!
    }
    
    // MARK: - Helpers
    
    /// 기준일(baseDate)에서 dayOffset만큼 더한 startDate ~ (startDate + (length-1)) 기간의 월경 기록 생성
    private func makeMenstrualRecord(
        dayOffsetFromBase: Int,
        length days: Int
    ) -> CycleRecord {
        let start = calendar.date(byAdding: .day, value: dayOffsetFromBase, to: baseDate)!
        let end = calendar.date(byAdding: .day, value: days - 1, to: start)!
        return CycleRecord(
            type: .menstrualRecord,
            startDate: start,
            endDate: end
        )
    }
    
    /// 날짜 비교 편의를 위해 "yyyy-MM-dd" 문자열로 변환
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Tests (기존 동작 검증)
    
    /// 최소 기록 수보다 적으면 예측이 생성되지 않아야 한다.
    func testNoPredictionsWhenNotEnoughRecords() {
        // given
        let config = CyclePredictionEngine.Config(
            minimumCyclesForPrediction: 2, // 최소 2개 사이클 필요
            numberOfFutureCycles: 3,
            userWeight: 0.5
        )
        let engine = CyclePredictionEngine(config: config)
        
        // 월경 기록: 2개 (사이클 길이는 1개밖에 못 구함)
        let r1 = makeMenstrualRecord(dayOffsetFromBase: 0, length: 5)
        let r2 = makeMenstrualRecord(dayOffsetFromBase: 28, length: 5)
        
        let records = [r1, r2]
        
        // when
        let predictions = engine.makePredictions(from: records)
        
        // then
        XCTAssertTrue(predictions.isEmpty, "충분한 월경 기록이 없으면 예측이 생성되지 않아야 합니다.")
    }
    
    /// 규칙적인 28일 주기, 5일 월경이 3번 있는 경우
    /// 평균 주기 = 28일, 평균 기간 = 5일로 계산되어
    /// 다음 두 주기의 예측이 올바른 날짜에 생성되는지 확인
    func testPredictionsWithRegular28DayCycle() {
        // given
        let config = CyclePredictionEngine.Config(
            minimumCyclesForPrediction: 2,
            numberOfFutureCycles: 2,   // 앞으로 2번 예측
            userWeight: 0.5
        )
        let engine = CyclePredictionEngine(config: config)
        
        // 월경 기록:
        // 1주기: day 0 ~ 4
        // 2주기: day 28 ~ 32
        // 3주기: day 56 ~ 60
        let r1 = makeMenstrualRecord(dayOffsetFromBase: 0, length: 5)
        let r2 = makeMenstrualRecord(dayOffsetFromBase: 28, length: 5)
        let r3 = makeMenstrualRecord(dayOffsetFromBase: 56, length: 5)
        
        let records = [r1, r2, r3]
        
        // when
        let predictions = engine.makePredictions(from: records)
        
        // then
        XCTAssertEqual(predictions.count, 2, "numberOfFutureCycles = 2 이므로 예측도 2개여야 합니다.")
        
        // 마지막 실제 월경 시작일 = base + 56일
        // 평균 주기 = 28일 → 예측1 시작일 = 56 + 28 = 84
        //                         예측2 시작일 = 56 + 56 = 112
        // 평균 기간 = 5일 → end = start + 4
        
        let expectedStartOffsets = [84, 112]
        
        for (index, prediction) in predictions.enumerated() {
            XCTAssertEqual(prediction.type, .menstrualPrediction, "예측 레코드의 type은 .menstrualPrediction이어야 합니다.")
            
            let expectedStart = calendar.date(byAdding: .day, value: expectedStartOffsets[index], to: baseDate)!
            let expectedEnd = calendar.date(byAdding: .day, value: 4, to: expectedStart)! // 5일 간
            
            XCTAssertEqual(dateString(prediction.startDate), dateString(expectedStart), "예측 \(index + 1)의 시작일이 기대값과 다릅니다.")
            XCTAssertEqual(dateString(prediction.endDate), dateString(expectedEnd), "예측 \(index + 1)의 종료일이 기대값과 다릅니다.")
        }
    }
    
    /// mergingPredictions는 기존 기록 + 예측을 시간 순으로 합쳐서 반환해야 한다.
    func testMergingPredictions() {
        // given
        let config = CyclePredictionEngine.Config(
            minimumCyclesForPrediction: 2,
            numberOfFutureCycles: 1,
            userWeight: 0.5
        )
        let engine = CyclePredictionEngine(config: config)
        
        let r1 = makeMenstrualRecord(dayOffsetFromBase: 0, length: 5)
        let r2 = makeMenstrualRecord(dayOffsetFromBase: 28, length: 5)
        let r3 = makeMenstrualRecord(dayOffsetFromBase: 56, length: 5)
        
        let records = [r3, r1, r2]   // 일부러 순서를 섞어둠
        
        // when
        let merged = engine.mergingPredictions(with: records)
        
        // 원하는 형식으로 문자열 만들기 (디버깅용)
        let debugText = merged
            .map { "\($0.type) | \($0.startDate) ~ \($0.endDate)" }
            .joined(separator: "\n")
        
        let attachment = XCTAttachment(string: debugText)
        attachment.name = "Merged Records Debug Output"
        attachment.lifetime = .keepAlways   // 테스트 끝나도 남겨둠
        add(attachment)
        
        // then
        // 1) 기존 3개 + 예측 1개
        XCTAssertEqual(merged.count, 4, "기존 3개 기록 + 예측 1개 = 4개여야 합니다.")
        
        // 2) 시간 순 정렬인지 확인
        let sortedByDate = merged.sorted { $0.startDate < $1.startDate }
        XCTAssertEqual(merged.map { dateString($0.startDate) },
                       sortedByDate.map { dateString($0.startDate) },
                       "mergingPredictions는 시작일 기준으로 정렬된 배열을 반환해야 합니다.")
        
        // 3) 마지막 하나는 예측이어야 한다.
        guard let last = merged.last else {
            XCTFail("merged 배열이 비어있습니다.")
            return
        }
        XCTAssertEqual(last.type, .menstrualPrediction, "마지막 요소는 미래 예측(.menstrualPrediction)이어야 합니다.")
    }
    
    // MARK: - Tests (사용자 입력 기반 동작 검증)
    
    /// 기록이 부족해도 사용자 입력이 있으면 그 값을 기반으로 예측을 생성해야 한다.
    func testPredictionsUseUserPreferenceWhenRecordsInsufficient() {
        // given
        let config = CyclePredictionEngine.Config(
            minimumCyclesForPrediction: 3,  // 기록만으로는 예측 불가
            numberOfFutureCycles: 1,
            userWeight: 0.7
        )
        let engine = CyclePredictionEngine(config: config)
        
        // 월경 기록: 1개뿐인 경우 (사이클 길이 자체를 계산할 수 없음)
        let r1 = makeMenstrualRecord(dayOffsetFromBase: 0, length: 5)
        let records = [r1]
        
        // 사용자 입력: 나는 보통 30일 주기에 5일 지속된다고 느낀다.
        let userPref = CyclePredictionEngine.UserCyclePreference(
            avgCycleLength: 30,
            avgPeriodLength: 5
        )
        
        // when
        let predictions = engine.makePredictions(from: records, userPreference: userPref)
        
        // then
        XCTAssertEqual(predictions.count, 1, "사용자 입력이 있으면 기록이 부족해도 예측 1개를 생성해야 합니다.")
        
        guard let prediction = predictions.first else {
            XCTFail("예측 결과가 비어 있습니다.")
            return
        }
        
        // 기준: 마지막 실제 월경 시작일 = base + 0일
        // 사용자 avgCycleLength = 30 → 예측 시작일 = base + 30
        // 사용자 avgPeriodLength = 5 → 종료일 = 시작 + 4
        let expectedStart = calendar.date(byAdding: .day, value: 30, to: baseDate)!
        let expectedEnd = calendar.date(byAdding: .day, value: 4, to: expectedStart)!
        
        XCTAssertEqual(dateString(prediction.startDate), dateString(expectedStart), "사용자 입력 기반 예측의 시작일이 기대값과 다릅니다.")
        XCTAssertEqual(dateString(prediction.endDate), dateString(expectedEnd), "사용자 입력 기반 예측의 종료일이 기대값과 다릅니다.")
    }
    
    /// 기록 기반 값과 사용자 입력이 모두 있을 때 userWeight에 따라 블렌딩된 주기가 사용되어야 한다.
    func testPredictionBlendsUserPreferenceAndEstimated() {
        // given
        let config = CyclePredictionEngine.Config(
            minimumCyclesForPrediction: 2,
            numberOfFutureCycles: 1,
            userWeight: 0.5    // 기록과 사용자 입력을 동일 비율로 섞기
        )
        let engine = CyclePredictionEngine(config: config)
        
        // 월경 기록: 정확한 28일 주기, 5일 지속이 3번
        let r1 = makeMenstrualRecord(dayOffsetFromBase: 0, length: 5)
        let r2 = makeMenstrualRecord(dayOffsetFromBase: 28, length: 5)
        let r3 = makeMenstrualRecord(dayOffsetFromBase: 56, length: 5)
        let records = [r1, r2, r3]
        
        // 기록 기반 평균 주기 = 28일, 평균 기간 = 5일
        // 사용자 입력: 주기는 32일로 느낀다, 기간은 그대로 5일
        // userWeight = 0.5 → 최종 평균 주기 = (28 + 32) / 2 = 30
        let userPref = CyclePredictionEngine.UserCyclePreference(
            avgCycleLength: 32,
            avgPeriodLength: 5
        )
        
        // when
        let predictions = engine.makePredictions(from: records, userPreference: userPref)
        
        // then
        XCTAssertEqual(predictions.count, 1, "앞으로 1개 주기를 예측해야 합니다.")
        
        guard let prediction = predictions.first else {
            XCTFail("예측 결과가 비어 있습니다.")
            return
        }
        
        // 마지막 실제 월경 시작일 = base + 56일
        // 최종 평균 주기 = 30일 → 예측 시작일 = 56 + 30 = 86
        // 평균 기간 = 5일 → 종료일 = 시작 + 4
        let expectedStart = calendar.date(byAdding: .day, value: 86, to: baseDate)!
        let expectedEnd = calendar.date(byAdding: .day, value: 4, to: expectedStart)!
        
        XCTAssertEqual(dateString(prediction.startDate), dateString(expectedStart), "블렌딩된 평균 주기에 기반한 예측 시작일이 기대값과 다릅니다.")
        XCTAssertEqual(dateString(prediction.endDate), dateString(expectedEnd), "블렌딩된 평균 기간에 기반한 예측 종료일이 기대값과 다릅니다.")
    }
}
