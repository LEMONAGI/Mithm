//
//  HealthKitCycleDataStore.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation
import HealthKit

actor HealthKitCycleDataStore {
    private let healthStore = HKHealthStore()
    private let calendar = Calendar.current
    
    
    static var writeTypes: Set<HKSampleType> {
        [menstrualType]
    }
    
    static var readTypes: Set<HKObjectType> {
        [menstrualType, basalTempType]
    }
    // 월경 주기 데이터 타입
    static var menstrualType: HKCategoryType {
        HKCategoryType(.menstrualFlow)
    }
    // 손목 온도 데이터 타입
    static var basalTempType: HKQuantityType {
        HKQuantityType(.basalBodyTemperature)
    }
    
    var isSharingAuthorized: Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        return healthStore.authorizationStatus(for: HealthKitCycleDataStore.menstrualType) == .sharingAuthorized
    }
    
    // MARK: - Authorization
    
    private func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }
        
        print("Requesting HealthKit authorization...")
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            
            healthStore.requestAuthorization(
                toShare: HealthKitCycleDataStore.writeTypes,
                read: HealthKitCycleDataStore.readTypes
            ) { success, error in
                
                if let error {
                    print("requestAuthorization error:", error.localizedDescription)
                    continuation.resume(throwing: error)
                    return
                }
                
                guard success else {
                    print("HealthKit authorization was not successful.")
                    continuation.resume(throwing: HealthKitError.authorizationDenied)
                    return
                }
                
                print("HealthKit authorization request was successful!")
                continuation.resume()
            }
        }
    }
    
    func verifyAuthorizationStatus() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }
        
        let status = healthStore.authorizationStatus(for: HealthKitCycleDataStore.menstrualType)
        
        switch status {
        case .sharingAuthorized:
            return
        case .notDetermined:
            try await requestAuthorization()
        case .sharingDenied:
            throw HealthKitError.authorizationDenied
        @unknown default:
            throw HealthKitError.authorizationDenied
        }
    }
    
    
    // MARK: - READ: menstrualFlow → CycleRecord(.menstrualRecord)
    /// HealthKit에서 월경 흐름 샘플을 읽어와서,
    /// 연속 구간별로 묶어 CycleRecord(.menstrualRecord) 배열로 변환.
    func fetchMenstrualRecords(
        from startDate: Date,
        to endDate: Date
    ) async throws -> [CycleRecord] {
        
        let menstrualType = HKCategoryType(.menstrualFlow)
        
        let samples: [HKCategorySample] = try await queryCategorySamples(
            type: menstrualType,
            from: startDate,
            to: endDate
        )
        
        return buildMenstrualEpisodes(from: samples)
    }
    
    
    /// HealthKit에서 기간 내의 해당 type 데이터 가져오기
    private func queryCategorySamples(
        type: HKCategoryType,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKCategorySample] {
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [.strictStartDate, .strictEndDate]
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let categorySamples = samples as? [HKCategorySample] ?? []
                continuation.resume(returning: categorySamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    
    /// 여러 날에 걸쳐 있는 menstrualFlow 샘플들을
    /// "연속된 날짜"를 기준으로 하나의 월경 기록으로 묶는다.
    private func buildMenstrualEpisodes(from samples: [HKCategorySample]) -> [CycleRecord] {
        guard !samples.isEmpty else { return [] }
        
        let days = samples
            .map { calendar.startOfDay(for: $0.startDate) }
            .sorted()
        
        var records: [CycleRecord] = []
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
                    CycleRecord(
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
        records.append(
            CycleRecord(
                type: .menstrualRecord,
                startDate: currentStart,
                endDate: currentEnd
            )
        )
        
        return records
    }
    
    
    // MARK: - WRITE: 우리 앱 기록 → HealthKit 월경 샘플
    
    /// 사용자가 "월경 시작 ~ 끝"을 우리 앱에 기록했을 때,
    /// 해당 구간 전체를 HealthKit의 menstrualFlow에 반영한다.
    ///
    /// - Parameters:
    ///   - startDate: 월경 시작일 (사용자가 선택한 날짜)
    ///   - endDate: 월경 종료일 (사용자가 선택한 날짜, startDate 이상)
    ///   - flow: 월경 강도 (기본값: .unspecified)
    func saveMenstrualEpisode(
        startDate: Date,
        endDate: Date,
        flow: HKCategoryValueVaginalBleeding = .unspecified
    ) async throws {
        guard let menstrualType = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else {
            throw HealthKitError.missingType
        }
        
        // 공유 권한 확인 (쓰기 가능 여부)
        guard isSharingAuthorized else {
            throw HealthKitError.noSharingPermission
        }
        
        let startDay = calendar.startOfDay(for: startDate)
        let endDay   = calendar.startOfDay(for: endDate)
        
        guard startDay <= endDay else { return }
        
        // 1) 먼저 해당 날짜 범위의 기존 월경 샘플 싹 삭제 (덮어쓰기 정책)
        try await deleteExistingMenstrualSamples(from: startDay, to: endDay)
        
        // 2) 그 다음에 우리 기준으로 per-day 샘플 다시 생성
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
                type: menstrualType,
                value: flow.rawValue,
                start: current,
                end: endOfCurrentDay,
                metadata: metadata
            )
            samples.append(sample)
            
            // 다음 날로 이동
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = nextDay
        }
        
        // 3) 저장
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(samples) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if !success {
                    continuation.resume(throwing: HealthKitError.authorizationDenied)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    /// 편의용: "월경 시작"만 알고 있을 때 (끝 모를 때)
    /// start == end 로 save 메서드에 넣어주어 한 날짜만 저장.
    func saveMenstrualStartDay(
        on date: Date,
        flow: HKCategoryValueVaginalBleeding = .unspecified
    ) async throws {
        try await saveMenstrualEpisode(startDate: date, endDate: date, flow: flow)
    }
    
    /// startDate~endDate 범위에 포함되는 기존 월경(bleeding) 샘플을 모두 삭제.
    /// (다른 앱/Health 앱에서 기록한 것도 포함해서 싹 지움)
    private func deleteExistingMenstrualSamples(
        from startDate: Date,
        to endDate: Date
    ) async throws {
        guard let menstrualType = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else {
            throw HealthKitError.missingType
        }
        
        // HealthKit 전체 사용 가능 여부 확인
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }
        
        // 이 구간 안에 걸치는 샘플 전부 삭제할 거라,
        // [startDay, endOfLastDay] 범위로 predicate 생성
        let startDay = calendar.startOfDay(for: startDate)
        
        var comps = calendar.dateComponents([.year, .month, .day], from: endDate)
        comps.hour = 23
        comps.minute = 59
        comps.second = 59
        guard let endOfLastDay = calendar.date(from: comps) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDay,
            end: endOfLastDay,
            options: []    // 겹치는 샘플 전부 포함
        )
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.deleteObjects(of: menstrualType,
                                      predicate: predicate) { success, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if !success {
                    continuation.resume(throwing: HealthKitError.authorizationDenied)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
