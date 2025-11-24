//
//  CycleRecord.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation

struct CycleRecord: Identifiable, Hashable {
    let id = UUID()
    let type: CycleRecordType
    let startDate: Date
    let endDate: Date?
}

extension CycleRecord {
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
