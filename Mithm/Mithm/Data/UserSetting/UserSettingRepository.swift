//
//  UserSettingRepository.swift
//  Mithm
//
//  Created by YunhakLee on 3/13/26.
//

import Foundation

/// 앱 설정(사용자 월경 정보, 캘린더 내보내기, 예측 모드 등)의 저장/불러오기를 추상화한다.
protocol UserSettingRepository {

    // MARK: - 사용자 월경 주기/기간 입력

    /// 사용자가 입력한 월경 주기/기간을 저장한다.
    func saveMenstrualUserInput(_ input: MenstrualUserInput)

    /// 저장된 사용자 월경 주기/기간을 불러온다. 저장된 값이 없으면 nil을 반환한다.
    func loadMenstrualUserInput() -> MenstrualUserInput?

    // MARK: - 캘린더 내보내기 활성화

    /// 캘린더 내보내기 기능 활성화 여부를 저장한다.
    func saveCalendarExportEnabled(_ enabled: Bool)

    /// 캘린더 내보내기 기능 활성화 여부를 불러온다. 저장된 값이 없으면 false를 반환한다.
    func loadCalendarExportEnabled() -> Bool

    // MARK: - 예측 엔진 UserInputMode

    /// 월경 주기 예측 엔진의 UserInputMode를 저장한다.
    func saveUserInputMode(_ mode: UserInputMode)

    /// 월경 주기 예측 엔진의 UserInputMode를 불러온다. 저장된 값이 없으면 nil을 반환한다.
    func loadUserInputMode() -> UserInputMode?
}
