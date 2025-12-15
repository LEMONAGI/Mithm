//
//  HealthKitRepositoryImplTests.swift
//  Mithm
//
//  Created by YunhakLee on 12/15/25.
//


import XCTest
import HealthKit
@testable import Mithm

final class HealthKitRepositoryImplTests: XCTestCase {

    func test_checkWriteAuthorization_whenHealthKitUnavailable_throwsNotAvailable() async {
        let ds = MockHealthKitDataStore()
        ds.isAvailable = false

        let repo = await HealthKitRepositoryImpl(dataStore: ds)

        do {
            try await repo.checkWriteAuthorization(for: .menstrualCycle)
            XCTFail("Expected throw")
        } catch let error as HealthKitError {
            XCTAssertEqual(error, .notAvailableOnDevice)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_checkWriteAuthorization_notDetermined_throwsAuthorizationNotDetermined() async {
        let ds = MockHealthKitDataStore()
        ds.writeAuthStatus = .notDetermined

        let repo = HealthKitRepositoryImpl(dataStore: ds)

        do {
            try await repo.checkWriteAuthorization(for: .menstrualCycle)
            XCTFail("Expected throw")
        } catch let error as HealthKitError {
            XCTAssertEqual(error, .authorizationNotDetermined)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_checkWriteAuthorization_denied_throwsAuthorizationDenied() async {
        let ds = MockHealthKitDataStore()
        ds.writeAuthStatus = .sharingDenied

        let repo = HealthKitRepositoryImpl(dataStore: ds)

        do {
            try await repo.checkWriteAuthorization(for: .menstrualCycle)
            XCTFail("Expected throw")
        } catch let error as HealthKitError {
            XCTAssertEqual(error, .authorizationDenied)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_requestAuthorization_mapsDomainTypes_andCallsDataStore() async throws {
        let ds = MockHealthKitDataStore()
        let repo = HealthKitRepositoryImpl(dataStore: ds)

        try await repo.requestAuthorization(
            writeTypes: [.menstrualCycle],
            readTypes: [.menstrualCycle, .basalTemperature]
        )

        XCTAssertTrue(ds.didRequestAuthorization)

        // write: menstrualFlow (category) 이어야 함
        XCTAssertTrue(ds.requestedAuthWriteTypes.contains(HKCategoryType(.menstrualFlow)))

        // read: menstrualFlow + basalBodyTemperature 이어야 함
        XCTAssertTrue(ds.requestedAuthReadTypes.contains(HKCategoryType(.menstrualFlow)))
        XCTAssertTrue(ds.requestedAuthReadTypes.contains(HKQuantityType(.basalBodyTemperature)))
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
    
    
    func test_readMenstrualCycleRecords_readsSamples_andMapsToCycleRecord() async throws {
        let ds = MockHealthKitDataStore()
        let repo = HealthKitRepositoryImpl(dataStore: ds)

        let type = HKCategoryType(.menstrualFlow)
        let cal = Calendar.current
        let d1 = cal.startOfDay(for: Date(timeIntervalSince1970: 0))
        let d2 = cal.date(byAdding: .day, value: 1, to: d1)!
        let s1 = makeMenstrualSample(day: d1, isCycleStart: true)
        let s2 = makeMenstrualSample(day: d2, isCycleStart: false)
        ds.readSamplesResult = [
            s1, s2
        ]

        let records = try await repo.readMenstrualCycleRecords(from: d1, to: d2)

        XCTAssertEqual(records.count, 1, "연속된 2일은 하나의 월경 record로 묶여야 함")
        XCTAssertEqual(records.first?.type, .menstrualRecord)
        XCTAssertTrue(Calendar.current.isDate(records[0].startDate, inSameDayAs: d1))
    }

    func test_updateMenstrualCycleRecord_deletesThenSaves() async throws {
        let ds = MockHealthKitDataStore()
        let repo = HealthKitRepositoryImpl(dataStore: ds)

        let cal = Calendar.current
        let start = cal.startOfDay(for: Date(timeIntervalSince1970: 0))
        let end = cal.date(byAdding: .day, value: 2, to: start)! // 3일

        let record = CycleRecord(type: .menstrualRecord, startDate: start, endDate: end)

        try await repo.updateMenstrualCycleRecord(record)

        XCTAssertFalse(ds.deleteCalls.isEmpty, "update는 저장 전 기존 샘플 삭제가 있어야 함")
        XCTAssertFalse(ds.savedObjects.isEmpty, "update는 새 샘플 저장이 있어야 함")

        // (정책) delete -> save 순서 보장
        XCTAssertEqual(ds.callOrder.first, "deleteSamples")
        XCTAssertTrue(ds.callOrder.contains("saveSamples"))
    }
}
