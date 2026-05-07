//
//  HealthKitMapper.swift
//  Mithm
//
//  Created by YunhakLee on 11/20/25.
//

import Foundation
import HealthKit

enum HealthKitMapper {

    /// Mapper 내부에서만 사용하는 타입 변환 에러.
    /// Repository에서 catch하여 HealthKitError로 매핑한다.
    enum MappingError: Error {
        case invalidTypeConversion(expected: String, actual: String)
    }

    static let calendar = Calendar.current
    
    // MARK: - Entity -> DTO
    
    static func hkObjectType(from type: HealthDataType) -> HKObjectType {
        switch type {
        case .menstrualCycle:
            return HKCategoryType(.menstrualFlow)
        case .wristTemperature:
            return HKQuantityType(.appleSleepingWristTemperature)
        }
    }
 
    static func hkCategoryType(from type: HealthDataType) throws -> HKCategoryType {
        let object = hkObjectType(from: type)
        guard let category = object as? HKCategoryType else {
            throw MappingError.invalidTypeConversion(
                expected: "HKCategoryType",
                actual: String(describing: Swift.type(of: object))
            )
        }
        return category
    }

    static func hkQuantityType(from type: HealthDataType) throws -> HKQuantityType {
        let object = hkObjectType(from: type)
        guard let quantity = object as? HKQuantityType else {
            throw MappingError.invalidTypeConversion(
                expected: "HKQuantityType",
                actual: String(describing: Swift.type(of: object))
            )
        }
        return quantity
    }
    
    static func hkSampleType(from type: HealthDataType) throws -> HKSampleType {
        let object = hkObjectType(from: type)
        guard let sample = object as? HKSampleType else {
            throw MappingError.invalidTypeConversion(
                expected: "HKSampleType",
                actual: String(describing: Swift.type(of: object))
            )
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
            guard let sample = try hkWritableSampleType(from: t) else { continue }
            result.insert(sample)
        }
        return result
    }

    /// HealthKit에 저장 가능한 샘플 타입만 반환한다.
    static func hkWritableSampleType(from type: HealthDataType) throws -> HKSampleType? {
        switch type {
        case .wristTemperature:
            return nil
        case .menstrualCycle:
            return try hkSampleType(from: type)
        }
    }
    
    
    /// 하나의 월경 기록을 여러 날에 걸쳐 있는 menstrualFlow 샘플들로 분리한다.
    static func hkMenstrualCycleSamples(from record: MenstrualRecord) throws -> [HKCategorySample] {
        let startDay = calendar.startOfDay(for: record.startDate)
        let endDay   = calendar.startOfDay(for: record.endDate ?? Date())
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
    /// 샘플이 여러 날에 걸쳐 있는 경우(startDate~endDate) 날짜 단위로 펼쳐서 처리한다.
    static func menstrualCycleRecords(from samples: [HKCategorySample]) -> [MenstrualRecord] {
        guard !samples.isEmpty else { return [] }
        
        var daySet = Set<Date>()
        for sample in samples {
            let start = calendar.startOfDay(for: sample.startDate)
            let end = calendar.startOfDay(for: sample.endDate)
            var current = start
            while current <= end {
                daySet.insert(current)
                guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
                current = next
            }
        }
        let days = daySet.sorted()
        
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
        
        // HealthKit 샘플은 항상 실제 기록된 날짜 범위로 읽고,
        // 현재 월경 여부는 별도 상태 계산 로직에서 판단한다.
        records.append(
            MenstrualRecord(
                type: .menstrualRecord,
                startDate: currentStart,
                endDate: currentEnd
            )
        )
        
        return records
    }

    static func wristTemperatureRecords(from samples: [HKQuantitySample]) -> [WristTemperatureRecord] {
        let unit = HKUnit.degreeCelsius()

        return samples.map {
            WristTemperatureRecord(
                startDate: $0.startDate,
                endDate: $0.endDate,
                valueInCelsius: $0.quantity.doubleValue(for: unit)
            )
        }
    }
}
