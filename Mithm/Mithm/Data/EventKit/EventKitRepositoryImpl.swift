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

    private enum ExportedEventReplacementWindow {
        static let pastYears = -40
        static let futureYears = 2
        // EventKit의 predicateForEvents는 공식적으로 4년 범위 제한이 있어,
        // 안전 마진을 두고 3년 단위로 조회 구간을 나눈다.
        static let queryChunkYears = 3
    }

    private let dataStore: EventKitDataStore
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.mithm",
        category: "EventKitRepository"
    )
    private let calendar: Calendar
    private let now: () -> Date

    init(
        dataStore: EventKitDataStore,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.dataStore = dataStore
        self.calendar = calendar
        self.now = now
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

    func clearExportedEvents() async throws {
        do {
            guard let calendar = try dataStore.fetchCalendarIfExists() else {
                return
            }
            let existingEvents = fetchExportedEvents(in: calendar)
            try dataStore.removeEvents(existingEvents)
            if !existingEvents.isEmpty {
                try dataStore.commit()
            }
        } catch {
            logger.error("내보낸 캘린더 이벤트 삭제 실패: \(error.localizedDescription)")
            dataStore.reset()
            throw EventKitError.syncFailed(error)
        }
    }


    // MARK: - Sync

    func syncRecordsToCalendar(_ records: [MenstrualRecord]) async throws {
        let parameters = EventKitMapper.eventParameters(from: records, calendar: calendar)

        let targetCalendar: EKCalendar
        if parameters.isEmpty {
            do {
                guard let existingCalendar = try dataStore.fetchCalendarIfExists() else {
                    return
                }
                targetCalendar = existingCalendar
            } catch {
                logger.error("기존 캘린더 조회 실패: \(error.localizedDescription)")
                throw EventKitError.syncFailed(error)
            }
        } else {
            do {
                targetCalendar = try dataStore.fetchOrCreateCalendar()
            } catch {
                logger.error("캘린더 생성 실패: \(error.localizedDescription)")
                throw EventKitError.noCalendarSource
            }
        }

        do {
            // 내보낼 이벤트를 내용 시그니처로 묶는다. (퇴화된 중복 입력은 자연스럽게 1개로 수렴)
            // param.endDate는 exclusive(마지막 날 + 1)이므로 -1일 보정해 캘린더 read-back과 같은
            // inclusive(마지막 날) 기준으로 맞춘다.
            var desiredByKey: [String: EventKitMapper.EventParameters] = [:]
            for param in parameters {
                let inclusiveEnd = calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: param.endDate
                ) ?? param.endDate
                let key = contentKey(
                    title: param.title,
                    startDate: param.startDate,
                    inclusiveEndDate: inclusiveEnd
                )
                desiredByKey[key] = param
            }

            // 캘린더에 이미 내보낸 미리듬 이벤트를 가져와 set-diff로 비교한다.
            let existingEvents = fetchExportedEvents(in: targetCalendar)

            var keptKeys: Set<String> = []
            var eventsToRemove: [EKEvent] = []
            for event in existingEvents {
                guard let key = contentKey(for: event), desiredByKey[key] != nil else {
                    // 내보낼 집합에 없거나 시그니처를 만들 수 없는(URL 손상) 이벤트 → 삭제
                    eventsToRemove.append(event)
                    continue
                }
                if keptKeys.contains(key) {
                    // 같은 내용이 이미 유지됨 → 과거 버그로 누적된 중복분 삭제
                    eventsToRemove.append(event)
                } else {
                    // 첫 매칭은 그대로 둔다(손대지 않음)
                    keptKeys.insert(key)
                }
            }

            try dataStore.removeEvents(eventsToRemove)

            // 캘린더에 아직 없는 시그니처만 새로 생성한다.
            let newEvents = desiredByKey.keys
                .filter { !keptKeys.contains($0) }
                .compactMap { key -> EKEvent? in
                    guard let param = desiredByKey[key] else { return nil }
                    return dataStore.makeEvent(
                        title: param.title,
                        notes: param.notes,
                        start: param.startDate,
                        end: param.endDate,
                        type: param.typeString,
                        in: targetCalendar
                    )
                }
            try dataStore.saveEvents(newEvents)

            if !eventsToRemove.isEmpty || !newEvents.isEmpty {
                try dataStore.commit()
            }
        } catch {
            logger.error("이벤트 동기화 실패: \(error.localizedDescription)")
            dataStore.reset()
            throw EventKitError.syncFailed(error)
        }
    }

    /// 캘린더에 내보낸 미리듬 이벤트를 넓은 범위에서 조회해 고유 목록으로 반환한다.
    /// `fetchOurEvents`가 mithm URL 이벤트만 돌려주므로, 사용자가 직접 추가한 일정은 포함되지 않는다.
    private func fetchExportedEvents(in targetCalendar: EKCalendar) -> [EKEvent] {
        let window = replacementWindow()
        var existingEventsByKey: [String: EKEvent] = [:]

        for queryWindow in replacementQueryWindows(from: window.start, to: window.end) {
            let predicate = dataStore.predicateForEvents(
                withStart: queryWindow.start,
                end: queryWindow.end,
                calendars: [targetCalendar]
            )
            let matchedEvents = dataStore.fetchOurEvents(matching: predicate)
            for event in matchedEvents {
                existingEventsByKey[dedupeKey(for: event)] = event
            }
        }

        return Array(existingEventsByKey.values)
    }

    // MARK: - Content Diff

    /// 이벤트 내용을 식별하는 시그니처. title은 MenstrualRecordType별로 distinct하므로
    /// 타입 식별 + 언어 변경 감지를 겸한다. 날짜는 일 단위로 정규화해 종일 이벤트 read-back/타임존에 견고하다.
    private func contentKey(title: String?, startDate: Date, inclusiveEndDate: Date) -> String {
        let start = Int(calendar.startOfDay(for: startDate).timeIntervalSince1970)
        let end = Int(calendar.startOfDay(for: inclusiveEndDate).timeIntervalSince1970)
        return "\(title ?? "")|\(start)|\(end)"
    }

    /// 캘린더에서 읽어온 실제 이벤트의 내용 시그니처를 만든다.
    /// 종일 이벤트의 endDate는 read-back 시 inclusive(마지막 날)이므로 그대로 사용한다.
    /// 사용자가 캘린더 앱에서 날짜·제목을 바꾸면 이 값이 달라져 변경이 감지된다.
    private func contentKey(for event: EKEvent) -> String? {
        guard let startDate = event.startDate,
              let endDate = event.endDate else {
            return nil
        }
        return contentKey(
            title: event.title,
            startDate: startDate,
            inclusiveEndDate: endDate
        )
    }

    private func replacementQueryWindows(
        from start: Date,
        to end: Date
    ) -> [(start: Date, end: Date)] {
        guard start < end else {
            return []
        }

        var windows: [(start: Date, end: Date)] = []
        var queryStart = start

        while queryStart < end {
            let nextYear = calendar.date(
                byAdding: .year,
                value: ExportedEventReplacementWindow.queryChunkYears,
                to: queryStart
            )
            let queryEnd = nextYear.map { min($0, end) } ?? end
            guard queryEnd > queryStart else {
                break
            }

            windows.append((start: queryStart, end: queryEnd))
            queryStart = queryEnd
        }

        return windows
    }

    private func dedupeKey(for event: EKEvent) -> String {
        // 삭제 대상은 항상 저장된 이벤트라 eventIdentifier를 가지므로 1순위로 사용한다.
        // 과거 버그로 누적된 "진짜 중복 이벤트"(같은 type+start라 URL이 동일)도 서로 다른
        // eventIdentifier를 가지므로 각각 별개로 삭제 대상에 잡힌다 — URL fallback이 이들을
        // 잘못 합치지 않는다. URL fallback은 eventIdentifier가 없는 미저장 이벤트에만 동작하며,
        // 이때 인스턴스가 달라도 안정적인 키를 제공해 ObjectIdentifier보다 견고하다.
        if let eventIdentifier = event.eventIdentifier, !eventIdentifier.isEmpty {
            return "id-\(eventIdentifier)"
        }

        if let url = event.url?.absoluteString {
            return "url-\(url)"
        }

        return "object-\(ObjectIdentifier(event).hashValue)"
    }

    private func replacementWindow() -> (start: Date, end: Date) {
        let referenceDate = now()
        let start = calendar.date(
            byAdding: .year,
            value: ExportedEventReplacementWindow.pastYears,
            to: referenceDate
        ) ?? referenceDate
        let end = calendar.date(
            byAdding: .year,
            value: ExportedEventReplacementWindow.futureYears,
            to: referenceDate
        ) ?? referenceDate
        return (start, end)
    }
}
