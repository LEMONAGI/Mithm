//
//  EventKitMapper.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import Foundation

/// MenstrualRecord(Domain) ↔ EventKit 이벤트 생성 파라미터 변환을 담당한다.
/// Core의 EventKitDataStore가 도메인 모델을 알 필요 없도록,
/// 여기서 title, notes, typeString 등을 추출하여 전달한다.
enum EventKitMapper {
    
    /// MenstrualRecord에서 이벤트 생성에 필요한 파라미터를 추출한다.
    struct EventParameters {
        let title: String
        let notes: String?
        let typeString: String
        let startDate: Date
        let endDate: Date
    }
    
    /// MenstrualRecord 배열을 이벤트 파라미터 배열로 변환한다.
    /// endDate가 없는 레코드는 건너뛴다.
    static func eventParameters(
        from records: [MenstrualRecord],
        calendar: Calendar = .current
    ) -> [EventParameters] {
        records.compactMap { record in
            guard let endDate = record.endDate,
                  let calendarEventEndDate = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: calendar.startOfDay(for: endDate)
                  )
            else {
                return nil
            }

            return EventParameters(
                title: record.type.title,
                notes: record.type.notes,
                typeString: record.type.typeString,
                startDate: calendar.startOfDay(for: record.startDate),
                endDate: calendarEventEndDate
            )
        }
    }
}
