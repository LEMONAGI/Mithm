//
//  OvulationWindowEngine.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation

struct OvulationWindowEngine {
    
    struct Config {
        /// 월경 시작일 기준 배란일까지 거꾸로 가는 일수 (일반적으로 14일)
        let lutealPhaseLength: Int
        /// 배란일 기준 "배란기 시작"까지 거꾸로 가는 일수 (4일 전)
        let windowBefore: Int
        /// 배란일 기준 "배란기 끝"까지 앞으로 가는 일수 (2일 후)
        let windowAfter: Int
        
        static let `default` = Config(
            lutealPhaseLength: 14,
            windowBefore: 4,
            windowAfter: 2
        )
    }
    
    let config: Config
    
    init(config: Config = .default) {
        self.config = config
    }
    
    /// 월경 기록/예측으로부터
    /// - 배란일(.ovulationEstimated/.ovulationPrediction)
    /// - 배란기(.ovulationFertileWindowEstimated/.ovulationFertileWindowPrediction)
    /// 레코드를 생성해서 반환
    func makeOvulationRecords(from records: [CycleRecord]) -> [CycleRecord] {
        let calendar = Calendar.current
        
        // 월경 기록 + 월경 예측만 사용
        let bases = records
            .filter { $0.type == .menstrualRecord || $0.type == .menstrualPrediction }
            .sorted { $0.startDate < $1.startDate }
        
        var result: [CycleRecord] = []
        
        for base in bases {
            let startOfDay = calendar.startOfDay(for: base.startDate)
            
            // 1) 배란일 = 월경 시작일 - lutealPhaseLength(14일)
            guard let ovulationDay = calendar.date(
                byAdding: .day,
                value: -config.lutealPhaseLength,
                to: startOfDay
            ) else {
                continue
            }
            
            // 2) 배란기 시작/끝
            guard let windowStart = calendar.date(
                byAdding: .day,
                value: -config.windowBefore,
                to: ovulationDay
            ), let windowEnd = calendar.date(
                byAdding: .day,
                value: config.windowAfter,
                to: ovulationDay
            ) else {
                continue
            }
            
            // 타입 결정: 과거 기록 기반인지, 예측 기반인지
            let ovulationDayType: CycleRecordType
            let windowType: CycleRecordType
            
            switch base.type {
            case .menstrualRecord:
                ovulationDayType = .ovulationEstimated
                windowType = .ovulationFertileWindowEstimated
            case .menstrualPrediction:
                ovulationDayType = .ovulationPrediction
                windowType = .ovulationFertileWindowPrediction
            default:
                continue
            }
            
            // 3) 배란일(하루짜리) 레코드
            let ovulationRecord = CycleRecord(
                type: ovulationDayType,
                startDate: ovulationDay,
                endDate: ovulationDay
            )
            
            // 4) 배란기(기간) 레코드
            let fertileWindowRecord = CycleRecord(
                type: windowType,
                startDate: windowStart,
                endDate: windowEnd
            )
            
            result.append(ovulationRecord)
            result.append(fertileWindowRecord)
        }
        
        return result
    }
}
