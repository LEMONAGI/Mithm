//
//  EventKitDataStore.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import EventKit

/// EventKit과 직접 통신하는 최하단 Core 레이어.
/// - 권한 확인, 캘린더 관리, 이벤트 CRUD 등 모든 EventKit 연산을 담당한다.
/// - Domain 모델에 대한 의존 없이 순수 EventKit 타입만 사용한다.
protocol EventKitDataStore {
    
    // MARK: - Authorization
    
    /// 현재 캘린더 접근 권한 상태를 반환합니다.
    var authorizationStatus: EKAuthorizationStatus { get }
    
    /// 현재 캘린더 전체 접근 권한이 있는지 확인합니다.
    var isFullAccessAuthorized: Bool { get }
    
    /// 현재 앱의 권한 상태를 확인하고, 그에 따른 처리를 합니다.
    /// - 전체 접근이면 true 반환, 미결정이면 권한 요청, 그 외 에러.
    func verifyAuthorizationStatus() async throws -> Bool
    
    
    // MARK: - Calendar
    
    /// 우리 앱 전용 캘린더를 가져오거나, 없으면 새롭게 생성합니다.
    func fetchOrCreateCalendar() throws -> EKCalendar
    
    
    // MARK: - Event CRUD
    
    /// 이벤트를 생성합니다.
    func makeEvent(
        title: String,
        notes: String?,
        start: Date,
        end: Date,
        type: String,
        in calendar: EKCalendar
    ) -> EKEvent
    
    /// 주어진 predicate에 해당하는 이벤트 중, 앱이 생성한 이벤트만 필터링하여 반환합니다.
    func fetchOurEvents(
        matching predicate: NSPredicate
    ) -> [EKEvent]
    
    /// 이벤트들을 삭제합니다 (커밋하지 않음).
    func removeEvents(_ events: [EKEvent]) throws
    
    /// 이벤트들을 저장합니다 (커밋하지 않음).
    func saveEvents(_ events: [EKEvent]) throws
    
    /// 배치 작업 후 커밋합니다.
    func commit() throws
    
    /// 커밋되지 않은 변경사항을 되돌립니다.
    func reset()
    
    /// 이벤트 predicate를 생성합니다.
    func predicateForEvents(
        withStart start: Date,
        end: Date,
        calendars: [EKCalendar]
    ) -> NSPredicate
    
    
    // MARK: - Change Notification
    
    /// 외부(캘린더 앱 등)에서 이벤트 데이터가 변경되었을 때 알림을 받는 AsyncStream.
    var storeChangedNotifications: AsyncStream<Void> { get }
}
