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
        let calendarUtil = Calendar.current
        let parameters = EventKitMapper.eventParameters(from: records, calendar: calendarUtil)

        do {
            try dataStore.deleteCalendarIfExists()
        } catch {
            logger.error("기존 캘린더 삭제 실패: \(error.localizedDescription)")
            throw EventKitError.syncFailed(error)
        }

        guard !parameters.isEmpty else { return }

        let calendar: EKCalendar
        do {
            calendar = try dataStore.fetchOrCreateCalendar()
        } catch {
            logger.error("캘린더 생성 실패: \(error.localizedDescription)")
            throw EventKitError.noCalendarSource
        }

        do {
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
