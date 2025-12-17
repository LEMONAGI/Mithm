//
//  HealthKitMapper.swift
//  Mithm
//
//  Created by YunhakLee on 11/20/25.
//

import Foundation
import HealthKit

enum HealthKitMapper {
    
    static let calendar = Calendar.current
    
    // MARK: - Entity -> DTO
    
    static func hkObjectType(from type: HealthDataType) -> HKObjectType {
        switch type {
        case .menstrualCycle:
            return HKCategoryType(.menstrualFlow)
        case .basalTemperature:
            return HKQuantityType(.basalBodyTemperature)
        }
    }
 
    static func hkCategoryType(from type: HealthDataType) throws -> HKCategoryType {
        let object = hkObjectType(from: type)
        guard let category = object as? HKCategoryType else {
            throw HealthKitError.invalidTypeForCategory
        }
        return category
    }

    static func hkQuantityType(from type: HealthDataType) throws -> HKQuantityType {
        let object = hkObjectType(from: type)
        guard let quantity = object as? HKQuantityType else {
            throw HealthKitError.invalidTypeForQuantity
        }
        return quantity
    }
    
    static func hkSampleType(from type: HealthDataType) throws -> HKSampleType {
        let object = hkObjectType(from: type)
        guard let sample = object as? HKSampleType else {
            throw HealthKitError.invalidTypeForSample
        }
        return sample
    }
    
    /// Set<HealthDataType>? -> Set<HKObjectType>?
    static func hkObjectTypes(from types: Set<HealthDataType>) -> Set<HKObjectType> {
        return Set(types.map { hkObjectType(from: $0) })
    }
    
    /// Set<HealthDataType>? -> Set<HKSampleType>?
    static func hkSampleTypes(from types: Set<HealthDataType>) throws -> Set<HKSampleType> {
        var result = Set<HKSampleType>()
        for t in types {
            let sample = try hkSampleType(from: t)
            result.insert(sample)
        }
        return result
    }
    
    
    /// 하나의 월경 기록을 여러 날에 걸쳐 있는 menstrualFlow 샘플들로 분리한다.
    static func hkMenstrualCycleSamples(from record: MenstrualRecord) throws -> [HKCategorySample] {
        let startDay = calendar.startOfDay(for: record.startDate)
        let endDay   = calendar.startOfDay(for: record.endDate ?? record.startDate)
        guard let healthType = record.type.healthDataType else { return [] }
        let type = try HealthKitMapper.hkCategoryType(from: healthType)
        let value = HKCategoryValueVaginalBleeding.unspecified
        
        var samples: [HKCategorySample] = []
        var current = startDay
        
        while current <= endDay {
            // 그 날의 23:59:59 만들기
            var comps = calendar.dateComponents([.year, .month, .day], from: current)
            comps.hour = 23
            comps.minute = 59
            comps.second = 59
            
            guard let endOfCurrentDay = calendar.date(from: comps) else { break }
            
            let isCycleStart = (current == startDay)
            let metadata: [String: Any] = [
                HKMetadataKeyMenstrualCycleStart: isCycleStart
            ]
            
            let sample = HKCategorySample(
                type: type,
                value: value.rawValue,
                start: current,
                end: endOfCurrentDay,
                metadata: metadata
            )
            samples.append(sample)
            
            // 다음 날로 이동
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = nextDay
        }
        
        return samples
    }
    
    // MARK: - DTO -> Entity
    
    /// 여러 날에 걸쳐 있는 menstrualFlow 샘플들을 "연속된 날짜"를 기준으로 하나의 월경 기록으로 묶는다.
    static func menstrualCycleRecords(from samples: [HKCategorySample]) -> [MenstrualRecord] {
        guard !samples.isEmpty else { return [] }
        
        let days = Array(
            Set(samples.map { calendar.startOfDay(for: $0.startDate) })
        ).sorted()
        
        var records: [MenstrualRecord] = []
        var currentStart = days[0]
        var currentEnd = days[0]
        
        for day in days.dropFirst() {
            // 하루씩 연속되는 경우 같은 에피소드로 묶기
            
            // currentEnd에 하루를 더한 날짜가, day 값과 동일하면 연속되는 경우이므로 currentEnd를 업데이트 하고 넘어감.
            if let next = calendar.date(byAdding: .day, value: 1, to: currentEnd),
               calendar.isDate(next, inSameDayAs: day) {
                currentEnd = day
            } else {
                // 끊기는 지점에서 하나의 기록 확정
                records.append(
                    MenstrualRecord(
                        type: .menstrualRecord,
                        startDate: currentStart,
                        endDate: currentEnd
                    )
                )
                // 새로운 기록 시작을 위한 세팅
                currentStart = day
                currentEnd = day
            }
        }
        
        // 마지막에는 끊기는 지점을 찾지 못하고 넘어가므로, 예외처리 추가
        if calendar.isDate(currentEnd, inSameDayAs: Date()) {   // currentEnd가 오늘이어서, 월경 종료 여부를 확인할 수 없는 경우
            records.append(
                MenstrualRecord(
                    type: .menstrualRecord,
                    startDate: currentStart,
                    endDate: nil
                )
            )
        } else {
            records.append(
                MenstrualRecord(
                    type: .menstrualRecord,
                    startDate: currentStart,
                    endDate: currentEnd
                )
            )
        }
        
        return records
    }
}

