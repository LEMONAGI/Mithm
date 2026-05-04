//
//  LoadUserSettingsUseCase.swift
//  Mithm
//

/// 앱 전역 설정 상태를 저장소 값에서 조립한다.
protocol LoadUserSettingsUseCase {
    func execute() -> UserSettingState
}
