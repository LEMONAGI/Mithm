//
//  RefreshMenstrualCycleUseCase.swift
//  Mithm
//

import Foundation

/// 월경 overview 조회, 진행 중 월경 상태 판정, 자동 종료, 캘린더 동기화를 한 곳에서 조율한다.
protocol RefreshMenstrualCycleUseCase {
    func execute(
        userSetting: UserSettingState,
        runAutoClose: Bool,
        referenceDate: Date
    ) async throws -> MenstrualCycleSnapshot
}

extension RefreshMenstrualCycleUseCase {
    func execute(
        userSetting: UserSettingState,
        runAutoClose: Bool
    ) async throws -> MenstrualCycleSnapshot {
        try await execute(
            userSetting: userSetting,
            runAutoClose: runAutoClose,
            referenceDate: Date()
        )
    }
}
