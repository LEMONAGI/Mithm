//
//  MenstrualCycleSnapshot.swift
//  Mithm
//

import Foundation

/// 월경 데이터 갱신 UseCase가 Presentation에 전달하는 단일 결과 모델.
struct MenstrualCycleSnapshot {
    let overview: MenstrualOverview
    let currentStatus: CurrentMenstrualStatus
}

struct MenstrualCycleRefreshError: Error {
    let snapshot: MenstrualCycleSnapshot
    let underlyingError: Error
}
