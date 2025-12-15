//
//  HealthKitMapperTests.swift
//  Mithm
//
//  Created by YunhakLee on 12/15/25.
//


import XCTest
import HealthKit
@testable import Mithm

final class HealthKitMapperTests: XCTestCase {

    func test_hkObjectTypes_mapsSet() {
        let result = HealthKitMapper.hkObjectTypes(from: [.menstrualCycle, .basalTemperature])
        XCTAssertEqual(result.count, 2)
    }

    func test_hkSampleTypes_mapsSet() throws {
        let result = try HealthKitMapper.hkSampleTypes(from: [.menstrualCycle, .basalTemperature])
        XCTAssertEqual(result.count, 2)
    }

    func test_hkMenstrualCycleSamples_createsDailySamples_andHasStartMetadata() throws {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date(timeIntervalSince1970: 0))
        let end = cal.date(byAdding: .day, value: 2, to: start)!  // 3일(0,1,2)

        let record = CycleRecord(
            type: .menstrualRecord,
            startDate: start,
            endDate: end
        )

        let samples = try HealthKitMapper.hkMenstrualCycleSamples(from: record)

        XCTAssertEqual(samples.count, 3, "start~end가 3일이면 샘플 3개 생성되어야 함")

        // 첫날: HKMetadataKeyMenstrualCycleStart = true
        let first = samples.first!
        let isStart = first.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool
        XCTAssertEqual(isStart, true)
    }
    
    private func makeMenstrualSample(
        day: Date,
        isCycleStart: Bool
    ) -> HKCategorySample {
        let type = HKCategoryType(.menstrualFlow)

        return HKCategorySample(
            type: type,
            value: HKCategoryValueVaginalBleeding.unspecified.rawValue,
            start: day,
            end: day,
            metadata: [
                HKMetadataKeyMenstrualCycleStart: isCycleStart
            ]
        )
    }
    
    func test_menstrualCycleRecords_groupsConsecutiveDays() {
        let type = HKCategoryType(.menstrualFlow)
        let cal = Calendar.current

        let d1 = cal.startOfDay(for: Date(timeIntervalSince1970: 0))
        let d2 = cal.date(byAdding: .day, value: 1, to: d1)!
        let d4 = cal.date(byAdding: .day, value: 3, to: d1)! // d1 + 3 = 4일째

        let s1 = makeMenstrualSample(day: d1, isCycleStart: true)
        let s2 = makeMenstrualSample(day: d2, isCycleStart: false)
        let s3 = makeMenstrualSample(day: d4, isCycleStart: true)

        let records = HealthKitMapper.menstrualCycleRecords(from: [s1, s2, s3])

        XCTAssertEqual(records.count, 2, "연속 2일 + 끊긴 1일 => 2개 record")

        XCTAssertEqual(records[0].type, .menstrualRecord)
        XCTAssertTrue(Calendar.current.isDate(records[0].startDate, inSameDayAs: d1))
        XCTAssertTrue(Calendar.current.isDate(records[0].endDate ?? records[0].startDate, inSameDayAs: d2))

        XCTAssertTrue(Calendar.current.isDate(records[1].startDate, inSameDayAs: d4))
    }
}
