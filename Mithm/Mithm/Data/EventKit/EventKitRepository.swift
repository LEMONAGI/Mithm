//
//  EventKitRepository.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import Foundation

/// Domain에서 캘린더 동기화 기능을 사용할 때 의존할 추상화.
/// EventKit에 대한 구체적인 사항을 Domain 측에서는 전혀 알 수 없도록 한다.
protocol EventKitRepository {
    
    /// 캘린더 전체 접근 권한을 확인하고, 필요 시 요청한다.
    func verifyCalendarAccess() async throws -> Bool
    
    /// 월경 기록을 앱 전용 캘린더에 동기화한다.
    /// 기존 이벤트를 모두 삭제하고, 입력받은 records 기반으로 새로 생성한다.
    func syncRecordsToCalendar(_ records: [MenstrualRecord]) async throws
}
