//
//  EventDataStore.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import EventKit
import UIKit

actor EventDataStore {
    let eventStore: EKEventStore
    
    /// 앱 전용 캘린더 이름
    private let calendarBaseTitle = "미듬"
    
    /// UserDefaults에 캘린더 ID 저장할 때 쓸 키
    private let calendarIdKey = "mithm_calendar_identifier"
    
    /// 우리 앱 이벤트를 식별하기 위한 URL 스킴
    private let eventURLBase = URL(string: "mithm://event")!
    
    init() {
        self.eventStore = EKEventStore()
    }
    
    
    // MARK: - Authorization
    
    /// 현재 캘린더 전체 접근 권한이 있는지 확인합니다.
    var isFullAccessAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }
    
    /// 캘린더 전체 접근 권한 요청을 합니다.
    private func requestFullAccess() async throws -> Bool {
        return try await eventStore.requestFullAccessToEvents()
    }
    
    /// 현재 앱의 권한 상태를 확인하고, 그에 따른 처리를 합니다.
    func verifyAuthorizationStatus() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess:
            return true
        case .notDetermined:
            return try await requestFullAccess()
        case .denied, .restricted, .writeOnly:
            throw EventKitError.accessFail
        @unknown default:
            throw EventKitError.accessFail
        }
    }
    
    
    // MARK: - Calendar
    
    /// 우리 앱 전용 캘린더를 가져오기 , 없으면 새롭게 생성
    func fetchOrCreateCalendar() throws -> EKCalendar {
        if let saved = loadSavedCalendar() {
            return saved
        }
        
        let source = try preferredSource()
        
        let uniqueTitle = makeUniqueCalendarTitle(base: calendarBaseTitle)
        
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = uniqueTitle
        calendar.source = source
        calendar.cgColor = UIColor.blue.cgColor
        
        try eventStore.saveCalendar(calendar, commit: true)
        UserDefaults.standard.set(calendar.calendarIdentifier, forKey: calendarIdKey)
        
        return calendar
    }
    
    /// 저장해 둔 calendarIdentifier로 캘린더를 복원
    private func loadSavedCalendar() -> EKCalendar? {
        guard let id = UserDefaults.standard.string(forKey: calendarIdKey) else {
            return nil
        }
        return eventStore.calendar(withIdentifier: id)
    }
    
    /// 전용 캘린더의 source 선택 (iCloud 선호, 없으면 local)
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
        
        throw EventKitError.noSuitableSource
    }
    
    private func makeUniqueCalendarTitle(base: String) -> String {
        let existingTitles = eventStore.calendars(for: .event).map(\.title)
        
        // 이미 없는 이름이면 그대로 사용
        guard existingTitles.contains(base) else {
            return base
        }
        
        // base, base (2), base (3)... 중 비어있는 첫 번호 찾기
        var index = 2
        while existingTitles.contains("\(base) (\(index))") {
            index += 1
        }
        return "\(base) (\(index))"
    }
    
    
    // MARK: - Event Helpers
    
    /// 단일 이벤트 만들기
    private func makeEvent(
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
        
        // URL 스킴으로 식별
        
        let ts = Int(start.timeIntervalSince1970)
        event.url = URL(string: "\(eventURLBase)?type=\(type)&start=\(ts)")
        
        return event
    }
    
    /// 우리가 만든 이벤트인지 확인
    private func isOurEvent(_ event: EKEvent) -> Bool {
        guard let url = event.url else { return false }
        return url.scheme == eventURLBase.scheme
    }
    
    /// 우리 앱 전용 캘린더에서,
    /// 이전 기록 + 예측을 전부 싹 지우고 입력받은 [CycleRecord] 기반으로 다시 생성.
    func replaceAllEvents(with records: [CycleRecord]) throws {
        guard !records.isEmpty else { return }
        
        let calendar = try fetchOrCreateCalendar()
        
        // 1) records의 범위 계산 (너무 멀리 말고, 실제 사용하는 기간만)
        let starts = records.map(\.startDate)
        let ends = records.map(\.endDate)
        
        guard let minStart = starts.min(),
              let maxEnd = ends.max() else {
            return
        }
        
        // 안전하게 앞뒤로 하루 정도 여유를 준다
        let calendarUtil = Calendar.current
        let paddedStart = calendarUtil.date(byAdding: .day, value: -100, to: minStart) ?? minStart
        let paddedEnd = calendarUtil.date(byAdding: .day, value: 100, to: maxEnd) ?? maxEnd
        
        let predicate = eventStore.predicateForEvents(
            withStart: paddedStart,
            end: paddedEnd,
            calendars: [calendar]
        )
        
        
        let allEvents = eventStore.events(matching: predicate).filter(isOurEvent)
        print(allEvents.count)
        do {
            // 2) 기존 이벤트 전부 삭제 (commit은 마지막에 한 번만)
            for event in allEvents {
                try eventStore.remove(event, span: .thisEvent, commit: false)
            }
            
            // 3) 새로운 기록/예측 전부 생성
            for record in records {
                let (title, notes, typeString) = titleNotesAndType(for: record.type)
                
                let event = makeEvent(
                    title: title,
                    notes: notes,
                    start: record.startDate,
                    end: record.endDate,
                    type: typeString,
                    in: calendar
                )
                
                try eventStore.save(event, span: .thisEvent, commit: false)
            }
            
            try eventStore.commit()
        } catch {
            eventStore.reset()
            throw EventKitError.eventCreationFail(error)
        }
    }
    
    /// kind에 따라 title/notes/HealthKit용 type 문자열 결정
    private func titleNotesAndType(for kind: CycleRecordType)
    -> (String, String?, String) {
        switch kind {
        case .menstrualRecord:
            return (
                "월경 기록",
                "사용자 기록에 기반한 실제 월경 기간입니다.",
                "menstrual_record"
            )
        case .ovulationEstimated:
            return (
                "배란일(추정)",
                "앱이 건강 기록을 기반으로 사후적으로 추정한 배란일입니다.",
                "ovulation_estimated"
            )
        case .menstrualPrediction:
            return (
                "월경 예정 기간",
                "앱에서 예측한 월경 예정 기간입니다.",
                "menstrual_prediction"
            )
        case .ovulationPrediction:
            return (
                "배란일(예상)",
                "앱에서 예측한 배란일입니다.",
                "ovulation_prediction"
            )
        }
    }
}

