//
//  EventKitRepositoryImplTests.swift
//  MithmTests
//

import EventKit
import Foundation
import Testing
@testable import Mithm

@MainActor
struct EventKitRepositoryImplTests {

    private let calendar = EventKitRepositoryTestCalendar.make()

    @Test("증분 동기화는 내용이 같은 기존 이벤트를 그대로 두고 아무 변경도 하지 않는다")
    func syncLeavesUnchangedEventsUntouched() async throws {
        let dataStore = FakeEventKitDataStore()
        dataStore.savedCalendar = dataStore.makeCalendar()
        let unchanged = record(.menstrualRecord, "2026-07-01", "2026-07-05")
        dataStore.eventsToFetch = [storedEvent(for: unchanged, in: dataStore)]
        let repository = EventKitRepositoryImpl(
            dataStore: dataStore,
            calendar: calendar,
            now: { date("2026-06-01 12:00") }
        )

        try await repository.syncRecordsToCalendar([unchanged])

        #expect(dataStore.deleteCalendarCallCount == 0)
        #expect(dataStore.removedEvents.isEmpty)
        #expect(dataStore.savedEvents.isEmpty)
        #expect(dataStore.commitCallCount == 0)
    }

    @Test("증분 동기화는 캘린더에 없는 이벤트만 새로 추가한다")
    func syncCreatesMissingEvents() async throws {
        let dataStore = FakeEventKitDataStore()
        dataStore.savedCalendar = dataStore.makeCalendar()
        // 기존 이벤트 없음
        let repository = EventKitRepositoryImpl(
            dataStore: dataStore,
            calendar: calendar,
            now: { date("2026-06-01 12:00") }
        )

        try await repository.syncRecordsToCalendar([
            record(.menstrualRecord, "2026-07-01", "2026-07-05")
        ])

        #expect(dataStore.removedEvents.isEmpty)
        #expect(dataStore.savedEvents.count == 1)
        #expect(dataStore.commitCallCount == 1)
    }

    @Test("증분 동기화는 더 이상 필요 없는 이벤트를 삭제하고 새 이벤트만 추가한다(넓은 범위·구간 경계 dedupe 포함)")
    func syncRemovesObsoleteAndAddsNew() async throws {
        let dataStore = FakeEventKitDataStore()
        dataStore.savedCalendar = dataStore.makeCalendar()
        // 같은 obsolete 이벤트가 구간 경계에서 서로 다른 인스턴스로 조회되는 상황을 모사
        // (동일 mithm URL 보유 → URL 기반 dedupe로 하나로 합쳐져야 함)
        let obsolete = record(.menstrualRecord, "2025-01-01", "2025-01-05")
        dataStore.eventsToFetchByCall = [
            [storedEvent(for: obsolete, in: dataStore)],
            [],
            [storedEvent(for: obsolete, in: dataStore)]
        ]
        let referenceDate = date("2026-06-01 12:00")
        let repository = EventKitRepositoryImpl(
            dataStore: dataStore,
            calendar: calendar,
            now: { referenceDate }
        )

        try await repository.syncRecordsToCalendar([
            record(.menstrualRecord, "2026-07-01", "2026-07-05")
        ])

        #expect(dataStore.deleteCalendarCallCount == 0)
        #expect(dataStore.predicateRanges.count == 14)
        #expect(dataStore.predicateRanges.first?.start == calendar.date(byAdding: .year, value: -40, to: referenceDate))
        #expect(dataStore.predicateRanges.last?.end == calendar.date(byAdding: .year, value: 2, to: referenceDate))
        #expect(dataStore.calls.filter { $0 == "predicateForEvents" }.count == 14)
        #expect(dataStore.calls.filter { $0 == "fetchOurEvents" }.count == 14)
        #expect(dataStore.removedEvents.count == 1)   // 구간 경계 dedupe로 1개로 합쳐진 obsolete 삭제
        #expect(dataStore.savedEvents.count == 1)
        #expect(dataStore.commitCallCount == 1)
        #expect(dataStore.calls.first == "fetchOrCreateCalendar")
        #expect(dataStore.callIndex(of: "removeEvents") < dataStore.callIndex(of: "makeEvent"))
        #expect(dataStore.callIndex(of: "makeEvent") < dataStore.callIndex(of: "saveEvents"))
        #expect(dataStore.callIndex(of: "saveEvents") < dataStore.callIndex(of: "commit"))
    }

    @Test("증분 동기화는 종료일이 바뀐 이벤트를 옛것 삭제 + 새것 생성으로 교체한다")
    func syncReplacesEventWhenContentChanged() async throws {
        let dataStore = FakeEventKitDataStore()
        dataStore.savedCalendar = dataStore.makeCalendar()
        // 기존: 7/1~7/5
        dataStore.eventsToFetch = [
            storedEvent(for: record(.menstrualRecord, "2026-07-01", "2026-07-05"), in: dataStore)
        ]
        let repository = EventKitRepositoryImpl(
            dataStore: dataStore,
            calendar: calendar,
            now: { date("2026-06-01 12:00") }
        )

        // desired: 7/1~7/7 (종료일 연장 → 다른 시그니처)
        try await repository.syncRecordsToCalendar([
            record(.menstrualRecord, "2026-07-01", "2026-07-07")
        ])

        #expect(dataStore.removedEvents.count == 1)
        #expect(dataStore.savedEvents.count == 1)
        #expect(dataStore.commitCallCount == 1)
    }

    @Test("증분 동기화는 제목이 바뀐 이벤트(사용자 수정/언어 변경)를 옛것 삭제 + 새것 생성으로 교체한다")
    func syncReplacesEventWhenTitleChanged() async throws {
        let dataStore = FakeEventKitDataStore()
        dataStore.savedCalendar = dataStore.makeCalendar()
        let rec = record(.menstrualRecord, "2026-07-01", "2026-07-05")
        let param = EventKitMapper.eventParameters(from: [rec], calendar: calendar)[0]
        let inclusiveEnd = calendar.date(byAdding: .day, value: -1, to: param.endDate)!
        // 날짜는 같지만 제목만 다른 기존 이벤트 (사용자가 제목을 고쳤거나 기기 언어가 바뀐 상황)
        let edited = dataStore.makeStoredEvent(
            type: param.typeString,
            start: param.startDate,
            end: inclusiveEnd,
            title: "사용자가 바꾼 제목"
        )
        dataStore.eventsToFetch = [edited]
        let repository = EventKitRepositoryImpl(
            dataStore: dataStore,
            calendar: calendar,
            now: { date("2026-06-01 12:00") }
        )

        try await repository.syncRecordsToCalendar([rec])

        #expect(dataStore.removedEvents.count == 1)   // 제목이 다른 옛 이벤트 삭제
        #expect(dataStore.savedEvents.count == 1)     // 올바른 제목으로 재생성
        #expect(dataStore.commitCallCount == 1)
    }

    @Test("증분 동기화는 같은 내용의 중복 누적 이벤트를 하나만 남기고 정리한다")
    func syncCollapsesDuplicateExistingEvents() async throws {
        let dataStore = FakeEventKitDataStore()
        dataStore.savedCalendar = dataStore.makeCalendar()
        let rec = record(.menstrualRecord, "2026-07-01", "2026-07-05")
        // 같은 내용(title/날짜)이지만 저장 식별이 다른 두 이벤트(과거 버그 누적분 모사).
        // 실제로는 eventIdentifier가 다르지만 테스트에선 설정 불가하므로 무시되는 dup 파라미터로
        // URL만 다르게 줘 fetch 단계 dedupe는 통과시키고(서로 다른 identity), 내용 시그니처는 동일하게 만든다.
        let dup1 = storedEvent(for: rec, in: dataStore, urlOverride: "mithm://event?type=menstrual_record&dup=1")
        let dup2 = storedEvent(for: rec, in: dataStore, urlOverride: "mithm://event?type=menstrual_record&dup=2")
        dataStore.eventsToFetch = [dup1, dup2]
        let repository = EventKitRepositoryImpl(
            dataStore: dataStore,
            calendar: calendar,
            now: { date("2026-06-01 12:00") }
        )

        try await repository.syncRecordsToCalendar([rec])

        #expect(dataStore.removedEvents.count == 1)   // 중복 1개 삭제
        #expect(dataStore.savedEvents.isEmpty)        // 유지된 1개로 충분 → 생성 없음
        #expect(dataStore.commitCallCount == 1)
    }

    @Test("빈 records 동기화는 기존 캘린더가 있을 때 미리듬 이벤트만 지운다")
    func syncWithEmptyRecordsClearsExistingCalendarEventsOnly() async throws {
        let dataStore = FakeEventKitDataStore()
        dataStore.savedCalendar = dataStore.makeCalendar()
        dataStore.eventsToFetch = [dataStore.makeStoredEvent()]
        let repository = EventKitRepositoryImpl(
            dataStore: dataStore,
            calendar: calendar,
            now: { date("2026-06-01 12:00") }
        )

        try await repository.syncRecordsToCalendar([])

        #expect(dataStore.deleteCalendarCallCount == 0)
        #expect(!dataStore.calls.contains("fetchOrCreateCalendar"))
        #expect(dataStore.removedEvents.count == 1)
        #expect(dataStore.savedEvents.isEmpty)
        #expect(dataStore.commitCallCount == 1)
    }

    @Test("빈 records 동기화는 기존 캘린더가 없으면 새 캘린더를 만들지 않는다")
    func syncWithEmptyRecordsDoesNothingWhenCalendarDoesNotExist() async throws {
        let dataStore = FakeEventKitDataStore()
        let repository = EventKitRepositoryImpl(
            dataStore: dataStore,
            calendar: calendar,
            now: { date("2026-06-01 12:00") }
        )

        try await repository.syncRecordsToCalendar([])

        #expect(dataStore.calls == ["fetchCalendarIfExists"])
        #expect(dataStore.deleteCalendarCallCount == 0)
        #expect(dataStore.removedEvents.isEmpty)
        #expect(dataStore.savedEvents.isEmpty)
        #expect(dataStore.commitCallCount == 0)
    }

    @Test("내보내기 이벤트 비우기는 캘린더를 삭제하지 않고 기존 미리듬 이벤트만 지운다")
    func clearExportedEventsKeepsCalendar() async throws {
        let dataStore = FakeEventKitDataStore()
        dataStore.savedCalendar = dataStore.makeCalendar()
        dataStore.eventsToFetch = [dataStore.makeStoredEvent()]
        let repository = EventKitRepositoryImpl(
            dataStore: dataStore,
            calendar: calendar,
            now: { date("2026-06-01 12:00") }
        )

        try await repository.clearExportedEvents()

        #expect(dataStore.deleteCalendarCallCount == 0)
        #expect(dataStore.removedEvents.count == 1)
        #expect(dataStore.savedEvents.isEmpty)
        #expect(dataStore.commitCallCount == 1)
    }

    @Test("미리듬 이벤트 식별은 mithm URL이 있으면 인식한다")
    func eventIdentifierMatchesEventWithMithmURL() {
        let dataStore = FakeEventKitDataStore()
        let event = dataStore.makeStoredEvent()

        #expect(EventKitEventIdentifier.isMithmEvent(event))
    }

    @Test("미리듬 이벤트 식별은 URL이 없으면 과거 제목/메모와 무관하게 제외한다")
    func eventIdentifierRejectsEventWithoutURL() {
        let dataStore = FakeEventKitDataStore()
        let event = dataStore.makeStoredEvent()
        event.url = nil
        event.title = "월경 기록"
        event.notes = "사용자 기록에 기반한 실제 월경 기간입니다."

        #expect(!EventKitEventIdentifier.isMithmEvent(event))
    }

    @Test("미리듬 이벤트 식별은 미리듬이 아닌 URL을 제외한다")
    func eventIdentifierRejectsNonMithmURL() {
        let dataStore = FakeEventKitDataStore()
        let event = dataStore.makeStoredEvent()
        event.url = URL(string: "https://example.com/event")

        #expect(!EventKitEventIdentifier.isMithmEvent(event))
    }

    @Test("사용자가 직접 추가한 일정은 미리듬 이벤트가 아니라 동기화 후보에서 제외된다(보존)")
    func userCreatedEventIsNotTreatedAsMithmEvent() {
        let dataStore = FakeEventKitDataStore()
        // 실기기에서는 Core의 fetchOurEvents가 isMithmEvent로 걸러 후보 집합에 넣지 않는다.
        // 여기서는 그 식별 계약을 고정한다: 미리듬 URL이 없는 사용자 일정은 false.
        let userEvent = dataStore.makeUserEvent()

        #expect(!EventKitEventIdentifier.isMithmEvent(userEvent))
    }

    private func record(
        _ type: MenstrualRecordType,
        _ start: String,
        _ end: String
    ) -> MenstrualRecord {
        MenstrualRecord(
            type: type,
            startDate: date(start),
            endDate: date(end)
        )
    }

    /// 주어진 record를 내보낸 뒤 캘린더에서 "읽어온" 이벤트를 재현한다.
    /// EventKit read-back을 모사: 종일 이벤트 종료일은 exclusive(+1)가 아니라 inclusive(마지막 날)다.
    /// title/날짜는 하드코딩하지 않고 실제 변환 결과와 일치시킨다.
    private func storedEvent(
        for record: MenstrualRecord,
        in store: FakeEventKitDataStore,
        urlOverride: String? = nil
    ) -> EKEvent {
        let param = EventKitMapper.eventParameters(from: [record], calendar: calendar)[0]
        let inclusiveEnd = calendar.date(byAdding: .day, value: -1, to: param.endDate) ?? param.endDate
        let event = store.makeStoredEvent(
            type: param.typeString,
            start: param.startDate,
            end: inclusiveEnd,
            title: param.title
        )
        if let urlOverride {
            event.url = URL(string: urlOverride)
        }
        return event
    }

    private func date(_ value: String) -> Date {
        EventKitRepositoryTestCalendar.date(value, calendar: calendar)
    }
}

private final class FakeEventKitDataStore: EventKitDataStore {
    private let eventStore = EKEventStore()

    var authorizationStatus: EKAuthorizationStatus = .fullAccess
    var isFullAccessAuthorized: Bool { authorizationStatus == .fullAccess }
    var storeChangedNotifications: AsyncStream<Void> {
        AsyncStream { _ in }
    }

    var savedCalendar: EKCalendar?
    var eventsToFetch: [EKEvent] = []
    var eventsToFetchByCall: [[EKEvent]] = []
    private(set) var calls: [String] = []
    private(set) var deleteCalendarCallCount = 0
    private(set) var removedEvents: [EKEvent] = []
    private(set) var savedEvents: [EKEvent] = []
    private(set) var commitCallCount = 0
    private(set) var resetCallCount = 0
    private(set) var predicateRanges: [(start: Date, end: Date)] = []

    func verifyAuthorizationStatus() async throws -> Bool {
        true
    }

    func fetchOrCreateCalendar() throws -> EKCalendar {
        calls.append("fetchOrCreateCalendar")
        if let savedCalendar {
            return savedCalendar
        }
        let calendar = makeCalendar()
        savedCalendar = calendar
        return calendar
    }

    func fetchCalendarIfExists() throws -> EKCalendar? {
        calls.append("fetchCalendarIfExists")
        return savedCalendar
    }

    func deleteCalendarIfExists() throws {
        calls.append("deleteCalendarIfExists")
        deleteCalendarCallCount += 1
        savedCalendar = nil
    }

    func makeEvent(
        title: String,
        notes: String?,
        start: Date,
        end: Date,
        type: String,
        in calendar: EKCalendar
    ) -> EKEvent {
        calls.append("makeEvent")
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = title
        event.notes = notes
        event.startDate = start
        event.endDate = end
        let ts = Int(start.timeIntervalSince1970)
        event.url = URL(string: "mithm://event?type=\(type)&start=\(ts)")
        return event
    }

    func fetchOurEvents(matching predicate: NSPredicate) -> [EKEvent] {
        calls.append("fetchOurEvents")
        if !eventsToFetchByCall.isEmpty {
            return eventsToFetchByCall.removeFirst()
        }

        return eventsToFetch
    }

    func removeEvents(_ events: [EKEvent]) throws {
        calls.append("removeEvents")
        removedEvents.append(contentsOf: events)
    }

    func saveEvents(_ events: [EKEvent]) throws {
        calls.append("saveEvents")
        savedEvents.append(contentsOf: events)
    }

    func commit() throws {
        calls.append("commit")
        commitCallCount += 1
    }

    func reset() {
        calls.append("reset")
        resetCallCount += 1
    }

    func predicateForEvents(
        withStart start: Date,
        end: Date,
        calendars: [EKCalendar]
    ) -> NSPredicate {
        calls.append("predicateForEvents")
        predicateRanges.append((start: start, end: end))
        return NSPredicate(value: true)
    }

    func makeCalendar() -> EKCalendar {
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "미리듬"
        return calendar
    }

    func makeStoredEvent(
        type: String = "menstrual_record",
        start: Date = Date(timeIntervalSince1970: 0),
        end: Date = Date(timeIntervalSince1970: 86_400),
        title: String = "월경 기록"
    ) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.calendar = savedCalendar ?? makeCalendar()
        event.title = title
        event.startDate = start
        event.endDate = end
        let ts = Int(start.timeIntervalSince1970)
        event.url = URL(string: "mithm://event?type=\(type)&start=\(ts)")
        return event
    }

    func makeUserEvent() -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.calendar = savedCalendar ?? makeCalendar()
        event.title = "친구 생일"
        event.startDate = Date(timeIntervalSince1970: 0)
        event.endDate = Date(timeIntervalSince1970: 86_400)
        // 미리듬 URL 없음 (사용자가 직접 추가한 일정)
        return event
    }

    func callIndex(of call: String) -> Int {
        calls.firstIndex(of: call) ?? Int.max
    }
}

private enum EventKitRepositoryTestCalendar {
    static func make() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    static func date(_ value: String, calendar: Calendar) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = value.contains(":") ? "yyyy-MM-dd HH:mm" : "yyyy-MM-dd"
        return formatter.date(from: value)!
    }
}
