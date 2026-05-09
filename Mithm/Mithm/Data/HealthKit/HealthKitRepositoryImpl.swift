//
//  HealthKitRepositoryImpl.swift
//  Mithm
//
//  Created by YunhakLee on 11/20/25.
//

import Foundation
import HealthKit
import os

final class HealthKitRepositoryImpl: HealthKitRepository {

    private let dataStore: HealthKitDataStore
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.mithm",
        category: "HealthKitRepository"
    )

    init(dataStore: HealthKitDataStore) {
        self.dataStore = dataStore
    }

    // MARK: - Authorization

    func checkWriteAuthorization(
        for type: HealthDataType
    ) async throws {
        guard dataStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }

        let hkObjectType = HealthKitMapper.hkObjectType(from: type)
        let status = dataStore.checkWriteAuthorization(for: hkObjectType)

        switch status {
        case .sharingAuthorized:
            return
        case .notDetermined:
            throw HealthKitError.authorizationNotDetermined
        case .sharingDenied:
            throw HealthKitError.authorizationDenied
        @unknown default:
            logger.warning("알 수 없는 권한 상태: \(String(describing: status))")
            throw HealthKitError.authorizationDenied
        }
    }

    func requestAuthorization(
        writeTypes: Set<HealthDataType>,
        readTypes: Set<HealthDataType>
    ) async throws {
        guard dataStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }

        do {
            let hkWriteTypes: Set<HKSampleType> = try HealthKitMapper.hkSampleTypes(from: writeTypes)
            let hkReadTypes: Set<HKObjectType> = HealthKitMapper.hkObjectTypes(from: readTypes)

            try await dataStore.requestAuthorization(
                writeTypes: hkWriteTypes,
                readTypes: hkReadTypes
            )
        } catch let error as HealthKitError {
            throw error
        } catch {
            logger.error("권한 요청 실패: \(error.localizedDescription)")
            throw HealthKitError.unknown
        }
    }

    // MARK: - MenstrualCycleRecord

    func readMenstrualCycleRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [MenstrualRecord] {
        do {
            let samples: [HKCategorySample] = try await dataStore.readCategorySamples(
                type: try HealthKitMapper.hkCategoryType(from: .menstrualCycle),
                from: startDate,
                to: endDate
            ).filter { $0.value != HKCategoryValueVaginalBleeding.none.rawValue}
            guard !samples.isEmpty else { throw HealthKitError.emptyResult }
            return HealthKitMapper.menstrualCycleRecords(from: samples)
        } catch let error as HealthKitError {
            throw error
        } catch {
            logger.error("월경 기록 읽기 실패: \(error.localizedDescription)")
            throw HealthKitError.readFailed
        }
    }

    func readWristTemperatureRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [WristTemperatureRecord] {
        do {
            let samples: [HKQuantitySample] = try await dataStore.readQuantitySamples(
                type: try HealthKitMapper.hkQuantityType(from: .wristTemperature),
                from: startDate,
                to: endDate
            )
            return HealthKitMapper.wristTemperatureRecords(from: samples)
        } catch let error as HealthKitError {
            throw error
        } catch {
            logger.error("손목 온도 읽기 실패: \(error.localizedDescription)")
            throw HealthKitError.readFailed
        }
    }

    func updateMenstrualCycleRecord(
        _ record: MenstrualRecord,
        deleteFrom: Date? = nil,
        deleteThrough: Date? = nil
    ) async throws {
        do {
            let objectType = HealthKitMapper.hkObjectType(from: .menstrualCycle)
            let deleteStart = deleteFrom ?? record.startDate
            let deleteEnd = deleteThrough ?? record.endDate ?? record.startDate
            try await dataStore.deleteSamples(
                type: objectType,
                from: deleteStart,
                to: deleteEnd
            )
        } catch let error as HealthKitError {
            throw error
        } catch {
            logger.error("월경 기록 삭제 실패: \(error.localizedDescription)")
            throw HealthKitError.deleteFailed
        }

        do {
            let samples = try HealthKitMapper.hkMenstrualCycleSamples(from: record)
            try await dataStore.saveSamples(samples: samples)
        } catch let error as HealthKitError {
            throw error
        } catch {
            logger.error("월경 기록 저장 실패: \(error.localizedDescription)")
            throw HealthKitError.writeFailed
        }
    }

    func deleteMenstrualCycleRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws {
        do {
            let objectType = HealthKitMapper.hkObjectType(from: .menstrualCycle)
            try await dataStore.deleteSamples(
                type: objectType,
                from: startDate,
                to: endDate
            )
        } catch let error as HealthKitError {
            throw error
        } catch {
            logger.error("월경 기록 삭제 실패: \(error.localizedDescription)")
            throw HealthKitError.deleteFailed
        }
    }
}
