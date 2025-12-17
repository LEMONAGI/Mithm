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
}

extension MenstrualRecord {
    /// 이 월경 기록의 길이(일수)
    var dayCount: Int? {
        guard let endDate else { return nil }
        let cal = Calendar.current
        let s = cal.startOfDay(for: startDate)
        let e = cal.startOfDay(for: endDate)
        let comps = cal.dateComponents([.day], from: s, to: e)
        return (comps.day ?? 0) + 1   // 양끝 포함
    }
}
