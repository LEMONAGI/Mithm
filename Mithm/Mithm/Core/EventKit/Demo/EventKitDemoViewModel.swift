//
//  EventStoreViewModel.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation
import EventKit
import Combine

@MainActor
final class EventKitDemoViewModel: ObservableObject {
    
    // MARK: - Published
    
    @Published var authorizationStatus: EKAuthorizationStatus
    @Published var isSyncing: Bool = false
    @Published var lastSyncedAt: Date?
    @Published var errorMessage: String?
    @Published var events: [EKEvent] = []
    
    // MARK: - Dependencies
    
    private let dataStore: EventKitDataStore
    
    init(dataStore: EventKitDataStore = EventKitDataStoreImpl()) {
        self.dataStore = dataStore
        self.authorizationStatus = dataStore.authorizationStatus
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .fullAccess
    }
    
    
    // MARK: - Authorization
    
    /// 권한 요청 + 상태 업데이트
    func requestAccess() {
        Task {
            do {
                let granted = try await dataStore.verifyAuthorizationStatus()
                authorizationStatus = dataStore.authorizationStatus
                
                if !granted {
                    errorMessage = "캘린더 전체 접근 권한이 허용되지 않았습니다."
                } else {
                    errorMessage = nil
                }
            } catch {
                authorizationStatus = dataStore.authorizationStatus
                errorMessage = "캘린더 권한 요청 실패: \(error.localizedDescription)"
            }
        }
    }
    
    
    // MARK: - Calendar
    
    /// 전용 캘린더 생성/확인
    func ensureCalendar() {
        Task {
            do {
                let calendar = try dataStore.fetchOrCreateCalendar()
                errorMessage = nil
                loadEvents(in: calendar)
            } catch {
                errorMessage = "캘린더 생성 실패: \(error.localizedDescription)"
            }
        }
    }
    
    
    // MARK: - Event CRUD
    
    /// 더미 이벤트 추가 (테스트용)
    func addDummyEvent() {
        Task {
            isSyncing = true
            defer { isSyncing = false }
            
            do {
                let calendar = try dataStore.fetchOrCreateCalendar()
                
                let now = Date()
                let cal = Calendar.current
                let start = cal.startOfDay(for: now)
                let end = cal.date(byAdding: .day, value: 4, to: start)!
                
                let event = dataStore.makeEvent(
                    title: "테스트 월경 기록",
                    notes: "데모에서 생성한 테스트 이벤트입니다.",
                    start: start,
                    end: end,
                    type: "menstrual_record",
                    in: calendar
                )
                
                try dataStore.saveEvents([event])
                try dataStore.commit()
                
                lastSyncedAt = Date()
                errorMessage = nil
                loadEvents(in: calendar)
                
            } catch {
                dataStore.reset()
                errorMessage = "이벤트 추가 실패: \(error.localizedDescription)"
            }
        }
    }
    
    /// 앱이 생성한 모든 이벤트 삭제
    func deleteAllOurEvents() {
        Task {
            isSyncing = true
            defer { isSyncing = false }
            
            do {
                let calendar = try dataStore.fetchOrCreateCalendar()
                
                let now = Date()
                let cal = Calendar.current
                let from = cal.date(byAdding: .year, value: -2, to: now)!
                let to = cal.date(byAdding: .year, value: 2, to: now)!
                
                let predicate = dataStore.predicateForEvents(
                    withStart: from,
                    end: to,
                    calendars: [calendar]
                )
                
                let existing = dataStore.fetchOurEvents(matching: predicate)
                
                guard !existing.isEmpty else {
                    errorMessage = "삭제할 이벤트가 없습니다."
                    return
                }
                
                try dataStore.removeEvents(existing)
                try dataStore.commit()
                
                lastSyncedAt = Date()
                errorMessage = nil
                loadEvents(in: calendar)
                
            } catch {
                dataStore.reset()
                errorMessage = "이벤트 삭제 실패: \(error.localizedDescription)"
            }
        }
    }
    
    /// 전용 캘린더의 이벤트 불러오기
    func refreshEvents() {
        Task {
            do {
                let calendar = try dataStore.fetchOrCreateCalendar()
                loadEvents(in: calendar)
                errorMessage = nil
            } catch {
                errorMessage = "이벤트 불러오기 실패: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadEvents(in calendar: EKCalendar) {
        let now = Date()
        let cal = Calendar.current
        let from = cal.date(byAdding: .year, value: -1, to: now)!
        let to = cal.date(byAdding: .year, value: 1, to: now)!
        
        let predicate = dataStore.predicateForEvents(
            withStart: from,
            end: to,
            calendars: [calendar]
        )
        
        events = dataStore.fetchOurEvents(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }
}
