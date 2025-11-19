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
    let endDate: Date
}
