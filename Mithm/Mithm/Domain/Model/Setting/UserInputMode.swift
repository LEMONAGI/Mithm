//
//  UserInputMode.swift
//  Mithm
//
//  Created by YunhakLee on 3/13/26.
//


enum UserInputMode {
    /// 사용자 입력만 사용하여 예측 (모델 예측 사용하지 않음)
    case onlyUserInput
    /// 모델 예측과 사용자 입력을 blend하여 예측
    case blendUserInput
    /// 사용자 입력을 무시하고 모델 예측만 사용
    case notBlendUserInput
}