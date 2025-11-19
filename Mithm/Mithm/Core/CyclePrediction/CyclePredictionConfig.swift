//
//  CyclePredictionConfig.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//


// CyclePredictionConfig.swift

import Foundation

struct CyclePredictionConfig {
    /// 예측에 사용할 최소 사이클 개수 (이보다 적으면 예측 안 함)
    let minimumCyclesForPrediction: Int
    /// 미래에 몇 주기까지 예측할지
    let numberOfFutureCycles: Int
    
    static let `default` = CyclePredictionConfig(
        minimumCyclesForPrediction: 2,
        numberOfFutureCycles: 3
    )
}