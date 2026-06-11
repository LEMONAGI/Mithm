//
//  OvulationRecordGenerator.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation

struct OvulationRecordGenerator {
    
    struct Config {
        /// 월경 시작일 기준 배란일까지 거꾸로 가는 일수 (일반적으로 14일)
        let lutealPhaseLength: Int
        /// 배란일 기준 "배란기 시작"까지 거꾸로 가는 일수 (5일 전)
        let windowBefore: Int
        /// 배란일 기준 "배란기 끝"까지 앞으로 가는 일수 (1일 후)
        let windowAfter: Int
        /// 이 값 미만의 주기(직전 월경 시작일과의 간격)를 가진 실제 월경 기록에는
        /// 배란기 추정을 생성하지 않는다. 주기가 너무 짧으면 역산한 배란일이
        /// 직전 월경 구간 안쪽으로 떨어져 신뢰할 수 없기 때문이다.
        /// MenstrualPredictionEngine.Config.validCycleRange 하한(20)과 일치시킨다.
        let minimumCycleLengthForOvulation: Int

        static let `default` = Config(
            lutealPhaseLength: 14,
            windowBefore: 5,
            windowAfter: 1,
            minimumCycleLengthForOvulation: 20
        )
    }
    
    let config: Config
    
    init(config: Config = .default) {
        self.config = config
    }
    
    /// 월경 기록/예측으로부터 배란일과 배란기 기록을 더해 생성한다.
    func generate(from records: [MenstrualRecord], calendar: Calendar = .current) -> [MenstrualRecord] {
        
        // 월경 기록 + 월경 예측만 사용
        let bases = records
            .filter { $0.type == .menstrualRecord || $0.type == .menstrualPrediction }
            .sorted { $0.startDate < $1.startDate }
            .reduce(into: [Date: MenstrualRecord]()) { recordsByStartDay, record in
                let startDay = calendar.startOfDay(for: record.startDate)
                guard let selectedRecord = recordsByStartDay[startDay] else {
                    recordsByStartDay[startDay] = record
                    return
                }

                if selectedRecord.type == .menstrualPrediction,
                   record.type == .menstrualRecord {
                    recordsByStartDay[startDay] = record
                }
            }
            .values
            .sorted { $0.startDate < $1.startDate }
        
        var result: [MenstrualRecord] = []
        var previousStartOfDay: Date?

        for base in bases {
            let startOfDay = calendar.startOfDay(for: base.startDate)
            defer { previousStartOfDay = startOfDay }

            // 실제 월경 기록은 직전 월경과의 주기가 너무 짧으면 배란기 추정을 건너뛴다.
            // (스킵 여부와 무관하게 위 defer가 다음 기록의 주기 기준점을 갱신한다)
            if base.type == .menstrualRecord, let previousStartOfDay {
                let cycleDays = calendar.dateComponents(
                    [.day],
                    from: previousStartOfDay,
                    to: startOfDay
                ).day ?? 0
                if cycleDays < config.minimumCycleLengthForOvulation {
                    continue
                }
            }

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
            let ovulationDayType: MenstrualRecordType
            let windowType: MenstrualRecordType
            
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
            let ovulationRecord = MenstrualRecord(
                type: ovulationDayType,
                startDate: ovulationDay,
                endDate: ovulationDay
            )
            
            // 4) 배란기(기간) 레코드
            let fertileWindowRecord = MenstrualRecord(
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
