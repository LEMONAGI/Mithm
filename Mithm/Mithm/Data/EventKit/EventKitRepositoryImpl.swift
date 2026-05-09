//
//  EventKitRepositoryImpl.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import Foundation
import EventKit
import os

final class EventKitRepositoryImpl: EventKitRepository {

    private let dataStore: EventKitDataStore
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.mithm",
        category: "EventKitRepository"
    )

    init(dataStore: EventKitDataStore) {
        self.dataStore = dataStore
    }
    
    
    // MARK: - Authorization
    
    func verifyCalendarAccess() async throws -> Bool {
        do {
            return try await dataStore.verifyAuthorizationStatus()
        } catch {
            logger.error("캘린더 접근 권한 확인 실패: \(error.localizedDescription)")
            throw EventKitError.accessDenied
        }
    }
    
    
    // MARK: - Remove Calendar

    func removeCalendar() async throws {
        do {
            try dataStore.deleteCalendarIfExists()
        } catch {
            logger.error("캘린더 삭제 실패: \(error.localizedDescription)")
            throw EventKitError.syncFailed(error)
        }
    }


    // MARK: - Sync

    func syncRecordsToCalendar(_ records: [MenstrualRecord]) async throws {
        guard !records.isEmpty else { return }
        
        let calendar: EKCalendar
        do {
            calendar = try dataStore.fetchOrCreateCalendar()
        } catch {
            logger.error("캘린더 생성/조회 실패: \(error.localizedDescription)")
            throw EventKitError.noCalendarSource
        }
        
        // records의 날짜 범위 계산
        let starts = records.map(\.startDate)
        let ends = records.compactMap(\.endDate)
        
        guard let minStart = starts.min(),
              let maxEnd = ends.max() else {
            return
        }
        
        let calendarUtil = Calendar.current
        let paddedStart = calendarUtil.date(byAdding: .day, value: -100, to: minStart) ?? minStart
        let paddedEnd = calendarUtil.date(byAdding: .day, value: 100, to: maxEnd) ?? maxEnd
        
        // 도메인 모델 → 이벤트 파라미터 변환
        let parameters = EventKitMapper.eventParameters(
            from: records,
            calendar: calendarUtil
        )
        
        let predicate = dataStore.predicateForEvents(
            withStart: paddedStart,
            end: paddedEnd,
            calendars: [calendar]
        )
        
        let existingEvents = dataStore.fetchOurEvents(matching: predicate)
        
        do {
            // 기존 이벤트 전부 삭제
            try dataStore.removeEvents(existingEvents)
            
            // 새로운 이벤트 생성
            let newEvents = parameters.map { param in
                dataStore.makeEvent(
                    title: param.title,
                    notes: param.notes,
                    start: param.startDate,
                    end: param.endDate,
                    type: param.typeString,
                    in: calendar
                )
            }
            
            try dataStore.saveEvents(newEvents)
            try dataStore.commit()
        } catch {
            logger.error("이벤트 동기화 실패: \(error.localizedDescription)")
            dataStore.reset()
            throw EventKitError.syncFailed(error)
        }
    }
}
