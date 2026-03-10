//
//  EventKitError.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//


enum EventKitError: Error {
    
    // MARK: Authorization
    
    case accessDenied                          // 캘린더 접근 권한 거부 또는 제한됨
    
    // MARK: Calendar
    
    case noCalendarSource                      // 캘린더를 생성할 수 있는 소스 없음
    
    // MARK: Sync
    
    case syncFailed(Error)                     // 이벤트 동기화(생성/삭제) 중 실패
}

extension EventKitError: Equatable {
    static func == (lhs: EventKitError, rhs: EventKitError) -> Bool {
        switch (lhs, rhs) {
        case (.accessDenied, .accessDenied),
             (.noCalendarSource, .noCalendarSource):
            return true
        case (.syncFailed, .syncFailed):
            return true
        default:
            return false
        }
    }
}
