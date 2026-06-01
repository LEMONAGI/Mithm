//
//  EventKitDataStoreImpl.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import EventKit
import os
import UIKit

actor EventKitDataStoreImpl: EventKitDataStore {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.mithm",
        category: "EventKitDataStore"
    )

    let eventStore: EKEventStore
    
    /// 앱 전용 캘린더 이름
    private var calendarBaseTitle: String {
        String(localized: "calendar.title")
    }
    
    /// UserDefaults에 캘린더 ID 저장할 때 쓸 키
    private let calendarIdKey = "mithm_calendar_identifier"
    
    /// 우리 앱 이벤트를 식별하기 위한 URL 스킴
    private let eventURLBase = URL(string: "mithm://event")!
    
    init() {
        self.eventStore = EKEventStore()
    }
    
    
    // MARK: - Authorization
    
    nonisolated var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }
    
    nonisolated var isFullAccessAuthorized: Bool {
        authorizationStatus == .fullAccess
    }
    
    func verifyAuthorizationStatus() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess:
            return true
        case .notDetermined:
            return try await eventStore.requestFullAccessToEvents()
        case .denied, .restricted, .writeOnly:
            throw EKError(.eventStoreNotAuthorized)
        @unknown default:
            throw EKError(.eventStoreNotAuthorized)
        }
    }
    
    
    // MARK: - Calendar
    
    func fetchOrCreateCalendar() throws -> EKCalendar {
        if let saved = loadSavedCalendar() {
            return saved
        }
        
        let source = try preferredSource()
        
        let uniqueTitle = makeUniqueCalendarTitle(base: calendarBaseTitle)
        
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = uniqueTitle
        calendar.source = source
        calendar.cgColor = UIColor.accent.cgColor
        
        try eventStore.saveCalendar(calendar, commit: true)
        UserDefaults.standard.set(calendar.calendarIdentifier, forKey: calendarIdKey)
        
        return calendar
    }
    
    private func loadSavedCalendar() -> EKCalendar? {
        guard let id = UserDefaults.standard.string(forKey: calendarIdKey) else {
            return nil
        }
        return eventStore.calendar(withIdentifier: id)
    }

    func fetchCalendarIfExists() throws -> EKCalendar? {
        loadSavedCalendar()
    }
    
    private func preferredSource() throws -> EKSource {
        if let icloud = eventStore.sources.first(where: {
            $0.sourceType == .calDAV && $0.title.contains("iCloud")
        }) {
            return icloud
        }
        
        if let local = eventStore.sources.first(where: {
            $0.sourceType == .local
        }) {
            return local
        }
        
        if let any = eventStore.sources.first {
            return any
        }
        
        throw EKError(.calendarHasNoSource)
    }
    
    func deleteCalendarIfExists() throws {
        guard let id = UserDefaults.standard.string(forKey: calendarIdKey),
              let calendar = eventStore.calendar(withIdentifier: id) else {
            return
        }
        try eventStore.removeCalendar(calendar, commit: true)
        UserDefaults.standard.removeObject(forKey: calendarIdKey)
    }

    private func makeUniqueCalendarTitle(base: String) -> String {
        let existingTitles = eventStore.calendars(for: .event).map(\.title)
        
        guard existingTitles.contains(base) else {
            return base
        }
        
        var index = 2
        while existingTitles.contains("\(base) (\(index))") {
            index += 1
        }
        return "\(base) (\(index))"
    }
    
    
    // MARK: - Event CRUD
    
    func makeEvent(
        title: String,
        notes: String?,
        start: Date,
        end: Date,
        type: String,
        in calendar: EKCalendar
    ) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = title
        event.notes = notes
        event.startDate = start
        event.endDate = end
        event.isAllDay = true

        let ts = Int(start.timeIntervalSince1970)
        event.url = URL(string: "\(eventURLBase)?type=\(type)&start=\(ts)")

        return event
    }
    
    nonisolated func fetchOurEvents(
        matching predicate: NSPredicate
    ) -> [EKEvent] {
        let events = eventStore.events(matching: predicate)
        let matchedEvents = events.filter { EventKitEventIdentifier.isMithmEvent($0) }

        Self.logger.info(
            """
            EventKit 미리듬 이벤트 식별 요약: \
            total=\(events.count, privacy: .public), \
            matched=\(matchedEvents.count, privacy: .public)
            """
        )

        return matchedEvents
    }

    func removeEvents(_ events: [EKEvent]) throws {
        for event in events {
            try eventStore.remove(event, span: .thisEvent, commit: false)
        }
    }
    
    func saveEvents(_ events: [EKEvent]) throws {
        for event in events {
            try eventStore.save(event, span: .thisEvent, commit: false)
        }
    }
    
    func commit() throws {
        try eventStore.commit()
    }
    
    func reset() {
        eventStore.reset()
    }
    
    nonisolated func predicateForEvents(
        withStart start: Date,
        end: Date,
        calendars: [EKCalendar]
    ) -> NSPredicate {
        eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: calendars
        )
    }
    
    
    // MARK: - Change Notification
    
    nonisolated var storeChangedNotifications: AsyncStream<Void> {
        AsyncStream { continuation in
            let observer = NotificationCenter.default.addObserver(
                forName: .EKEventStoreChanged,
                object: eventStore,
                queue: .main
            ) { _ in
                continuation.yield()
            }
            
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

enum EventKitEventIdentifier {
    private static let supportedURLHosts: Set<String> = [
        "event",
        "mithm.app"
    ]

    /// 미리듬이 생성한 이벤트인지 식별한다.
    /// - 미리듬은 최초 출시부터 모든 이벤트에 `mithm://event...` URL을 부여해 왔으므로,
    ///   URL만으로 식별이 가능하다. (제목/메모 기반 fallback은 사용자 이벤트 오삭제 위험이 있어 사용하지 않는다.)
    static func isMithmEvent(_ event: EKEvent) -> Bool {
        guard let url = event.url else {
            return false
        }
        return isMithmEventURL(url)
    }

    private static func isMithmEventURL(_ url: URL) -> Bool {
        if url.scheme == "mithm" {
            return true
        }

        guard url.scheme == "https",
              let host = url.host else {
            return false
        }

        return supportedURLHosts.contains(host)
            && url.path.hasPrefix("/event")
    }
}
