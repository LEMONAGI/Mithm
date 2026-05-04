//
//  EventKitError.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import Foundation


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

// MARK: - Alert Info

extension EventKitError: AlertPresentable {
    var alertTitle: String {
        switch self {
        case .accessDenied:
            return String(localized: "캘린더 접근 권한이 필요해요")
        case .noCalendarSource:
            return String(localized: "캘린더를 생성할 수 없어요")
        case .syncFailed:
            return String(localized: "캘린더 동기화에 실패했어요")
        }
    }

    var alertMessage: String {
        switch self {
        case .accessDenied:
            return String(localized: "설정 > 개인정보 보호 > 캘린더에서\nMithm의 접근 권한을 확인해 주세요.")
        case .noCalendarSource:
            return String(localized: "캘린더 계정을 추가한 뒤 다시 시도해 주세요.")
        case .syncFailed:
            return String(localized: "캘린더에 월경 기록을 내보내지 못했어요.\n잠시 후 다시 시도해 주세요.")
        }
    }
}
