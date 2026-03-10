//
//  HealthKitDemoViewModel.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitDemoViewModel: ObservableObject {
    
    // MARK: - Published
    
    @Published var samples: [HKCategorySample] = []
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isAuthorized: Bool = false
    
    // MARK: - Dependencies
    
    private let dataStore: HealthKitDataStore
    private let menstrualFlowType = HKCategoryType(.menstrualFlow)
    
    init(dataStore: HealthKitDataStore = HealthKitDataStoreImpl()) {
        self.dataStore = dataStore
    }
    
    
    // MARK: - Authorization
    
    /// 권한 요청 + 데이터 불러오기
    func requestAndLoad() {
        Task {
            await loadSamples(requestPermissionIfNeeded: true)
        }
    }
    
    /// 데이터만 다시 불러오기
    func reload() {
        Task {
            await loadSamples(requestPermissionIfNeeded: false)
        }
    }
    
    
    // MARK: - Read
    
    private func loadSamples(requestPermissionIfNeeded: Bool) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if requestPermissionIfNeeded {
                try await dataStore.requestAuthorization(
                    writeTypes: [menstrualFlowType],
                    readTypes: [menstrualFlowType]
                )
            }
            isAuthorized = true
            
            let now = Date()
            let from = Calendar.current.date(byAdding: .year, value: -1, to: now)!
            let to = Calendar.current.date(byAdding: .month, value: 1, to: now)!
            
            let fetched = try await dataStore.readCategorySamples(
                type: menstrualFlowType,
                from: from,
                to: to
            )
            samples = fetched.sorted { $0.startDate < $1.startDate }
            lastSyncDate = Date()
            errorMessage = nil
            
        } catch {
            errorMessage = "HealthKit 데이터 로드 실패: \(error.localizedDescription)"
            isAuthorized = false
        }
    }
    
    
    // MARK: - Write
    
    /// 월경 기록을 HealthKit에 저장
    func addMenstrualRecord(
        startDate: Date,
        endDate: Date,
        flow: HKCategoryValueVaginalBleeding
    ) {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await dataStore.requestAuthorization(
                    writeTypes: [menstrualFlowType],
                    readTypes: [menstrualFlowType]
                )
                
                // 기존 데이터 삭제 후 저장
                try await dataStore.deleteSamples(
                    type: menstrualFlowType,
                    from: startDate,
                    to: endDate
                )
                
                let hkSamples = makeMenstrualSamples(
                    start: startDate,
                    end: endDate,
                    flow: flow
                )
                try await dataStore.saveSamples(samples: hkSamples)
                
                // 저장 후 다시 불러오기
                await loadSamples(requestPermissionIfNeeded: false)
                
            } catch {
                errorMessage = "월경 기록 저장 실패: \(error.localizedDescription)"
            }
        }
    }
    
    
    // MARK: - Delete
    
    /// 지정한 기간의 월경 기록 삭제
    func deleteMenstrualRecord(startDate: Date, endDate: Date) {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await dataStore.deleteSamples(
                    type: menstrualFlowType,
                    from: startDate,
                    to: endDate
                )
                
                await loadSamples(requestPermissionIfNeeded: false)
                
            } catch {
                errorMessage = "월경 기록 삭제 실패: \(error.localizedDescription)"
            }
        }
    }
    
    
    // MARK: - Helpers
    
    /// 시작일~종료일을 하루 단위 HKCategorySample 배열로 변환
    private func makeMenstrualSamples(
        start: Date,
        end: Date,
        flow: HKCategoryValueVaginalBleeding
    ) -> [HKObject] {
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        
        var result: [HKObject] = []
        var current = startDay
        
        while current <= endDay {
            var comps = cal.dateComponents([.year, .month, .day], from: current)
            comps.hour = 23; comps.minute = 59; comps.second = 59
            guard let endOfDay = cal.date(from: comps) else { break }
            
            let isCycleStart = (current == startDay)
            let metadata: [String: Any] = [
                HKMetadataKeyMenstrualCycleStart: isCycleStart
            ]
            
            let sample = HKCategorySample(
                type: menstrualFlowType,
                value: flow.rawValue,
                start: current,
                end: endOfDay,
                metadata: metadata
            )
            result.append(sample)
            
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        
        return result
    }
}

