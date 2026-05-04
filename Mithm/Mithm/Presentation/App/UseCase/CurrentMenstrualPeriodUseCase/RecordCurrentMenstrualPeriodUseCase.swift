//
//  RecordCurrentMenstrualPeriodUseCase.swift
//  Mithm
//

import Foundation

/// 사용자의 월경 시작/종료 액션을 HealthKit 기록과 현재 episode 저장소에 반영한다.
protocol RecordCurrentMenstrualPeriodUseCase {
    func start(on startDate: Date) async throws
    func end(on endDate: Date, currentStatus: CurrentMenstrualStatus) async throws -> Bool
}
