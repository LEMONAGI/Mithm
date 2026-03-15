//
//  HomePhaseUseCase.swift
//  Mithm
//
//  Created by Codex on 8/13/25.
//

import Foundation

/// 홈 화면에서 사용할 현재 phase와 해당 구간을 계산한다.
///
/// 입력값 우선순위는 다음과 같다.
/// 1. 사용자가 직접 시작한 진행 중 월경(AppStorage 기반)
/// 2. 오늘이 포함된 월경 record
/// 3. 오늘이 포함된 배란기/배란 record
/// 4. 인접한 월경기-배란기 사이 gap(난포기)
/// 5. 인접한 배란기-월경기 사이 gap(황체기)
/// 6. record가 일부만 있을 때의 fallback
protocol HomePhaseUseCase {
    /// 현재 날짜 기준 phase와 표시 구간을 반환한다.
    ///
    /// - Parameters:
    ///   - menstrualOverview: 월경 실제 기록, 예측 기록, 배란 관련 기록을 모두 포함한 overview
    ///   - activeMenstrualStartDate: 사용자가 월경 시작 버튼을 눌러 별도로 진행 중인 월경 시작일
    ///   - today: 테스트 가능성을 위한 기준 날짜
    /// - Returns: 홈 화면에서 표시할 현재 phase와 날짜 구간
    func execute(
        menstrualOverview: MenstrualOverview,
        activeMenstrualStartDate: Date?,
        today: Date
    ) -> PhaseWindow
}
