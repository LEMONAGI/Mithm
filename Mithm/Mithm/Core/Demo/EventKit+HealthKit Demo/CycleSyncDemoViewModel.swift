//
//  CycleSyncDemoViewModel.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//


// CycleSyncDemoViewModel.swift

import Foundation
import SwiftUI
import Combine

@MainActor
final class CycleSyncDemoViewModel: ObservableObject {
    
    @Published var records: [CycleRecord] = []
    @Published var statusMessage: String?
    @Published var isSyncing: Bool = false
    
    private let healthStore = HealthKitCycleDataStore()
    private let eventStore = EventDataStore()
    
    /// HealthKit → CycleRecord → 캘린더까지 한 번에 싱크
    func syncHealthToCalendar() {
        Task {
            await sync()
        }
    }
    
    private func sync() async {
        isSyncing = true
        statusMessage = nil
        
        defer { isSyncing = false }
        
        // 1) HealthKit 권한 확인
        do {
            try await healthStore.verifyAuthorizationStatus()
        } catch {
            statusMessage = "HealthKit 권한이 필요합니다: \(error.localizedDescription)"
            return
        }
        
        // 2) HealthKit에서 월경 기록 가져오기
        let now = Date()
        let calendar = Calendar.current
        
        // 예시: 과거 1년 ~ 미래 3개월 사이만 사용
        let from = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        let to   = calendar.date(byAdding: .month, value: 3, to: now) ?? now
        
        var menstrualRecords: [CycleRecord] = []
        
        do {
            menstrualRecords = try await healthStore.fetchMenstrualRecords(
                from: from,
                to: to
            )
            menstrualRecords.sort { $0.startDate < $1.startDate }
            self.records = menstrualRecords
        } catch {
            statusMessage = "HealthKit에서 월경 데이터를 가져오는 중 오류가 발생했습니다: \(error.localizedDescription)"
            return
        }
        
        guard !menstrualRecords.isEmpty else {
            statusMessage = "HealthKit에서 월경 기록을 찾지 못했습니다."
            return
        }
        
        // 3) EventKit 권한 확인
        do {
            _ = try await eventStore.verifyAuthorizationStatus()
        } catch {
            statusMessage = "캘린더 접근 권한이 필요합니다: \(error.localizedDescription)"
            return
        }
        
        // 4) 전용 캘린더에 기록 내보내기
        do {
            try await eventStore.replaceAllEvents(with: menstrualRecords)
            statusMessage = "캘린더 동기화 완료! (\(menstrualRecords.count)개 기록 내보냄)"
        } catch {
            statusMessage = "캘린더 이벤트 생성 중 오류가 발생했습니다: \(error.localizedDescription)"
        }
    }
}
