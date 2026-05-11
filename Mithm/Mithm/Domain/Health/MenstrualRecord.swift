//
//  MenstrualRecord.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation

struct MenstrualRecord: Identifiable, Hashable {
    let id = UUID()
    let type: MenstrualRecordType
    let startDate: Date
    let endDate: Date?
    let isEditable: Bool

    init(type: MenstrualRecordType, startDate: Date, endDate: Date?, isEditable: Bool = true) {
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.isEditable = isEditable
    }
}

extension MenstrualRecord {
    /// 이 월경 기록의 길이(일수)
    var dayCount: Int? {
        dayCount(calendar: .current)
    }

    /// 지정된 캘린더를 사용하여 월경 기록의 길이(일수)를 계산
    func dayCount(calendar: Calendar) -> Int? {
        guard let endDate else { return nil }
        let s = calendar.startOfDay(for: startDate)
        let e = calendar.startOfDay(for: endDate)
        let comps = calendar.dateComponents([.day], from: s, to: e)
        return (comps.day ?? 0) + 1   // 양끝 포함
    }
}
