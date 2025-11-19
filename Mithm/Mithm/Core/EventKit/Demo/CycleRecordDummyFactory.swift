//
//  CycleRecordDummyFactory.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation

enum CycleRecordDummyFactory {
    
    /// 과거 1년 + 미래 6개월 더미 데이터 생성
    static func makeDummyRecords() -> [CycleRecord] {
        var results: [CycleRecord] = []
        
        let calendar = Calendar.current
        let now = Date()
        
        /// 랜덤한 주기 길이 (28~32일)
        func randomCycleLength() -> Int {
            Int.random(in: 28...32)
        }
        
        /// 랜덤한 월경 길이 (4~6일)
        func randomMenstrualLength() -> Int {
            Int.random(in: 4...6)
        }
        
        /// day offset helper
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: now)!
        }
        
        // MARK: - 1) 과거 1년치 생성
        
        var offset = -365
        
        while offset < -10 { // 오늘 기준 10일 전까지 과거 기록 생성
            let cycleLength = randomCycleLength()
            let menstrualLength = randomMenstrualLength()
            
            let start = day(offset)
            let end = day(offset + menstrualLength)
            
            // 월경 기록
            results.append(
                CycleRecord(
                    type: .menstrualRecord,
                    startDate: start,
                    endDate: end
                )
            )
            
            // 배란일 추정 = 다음 월경 시작 14일 전 (또는 이번 월경 종료 후 14일 뒤)
            let ovulation = calendar.date(byAdding: .day, value: 14, to: start)!
            
            results.append(
                CycleRecord(
                    type: .ovulationEstimated,
                    startDate: ovulation,
                    endDate: ovulation
                )
            )
            
            offset += cycleLength
        }
        
        // MARK: - 2) 미래 6개월치 예상 생성
        
        var futureOffset = 0
        
        while futureOffset < 180 {
            let cycleLength = randomCycleLength()
            let menstrualLength = randomMenstrualLength()
            
            let start = day(futureOffset)
            let end = day(futureOffset + menstrualLength)
            
            // 월경 예정
            results.append(
                CycleRecord(
                    type: .menstrualPrediction,
                    startDate: start,
                    endDate: end
                )
            )
            
            // 배란일 예상 = 월경 예정 시작 14일 전
            let ovulation = calendar.date(byAdding: .day, value: -14, to: start)!
            
            results.append(
                CycleRecord(
                    type: .ovulationPrediction,
                    startDate: ovulation,
                    endDate: ovulation
                )
            )
            
            futureOffset += cycleLength
        }
        
        return results.sorted { $0.startDate < $1.startDate }
    }
}
