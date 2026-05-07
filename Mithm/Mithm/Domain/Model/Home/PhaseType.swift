//
//  PhaseType.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

enum PhaseType: Int, Hashable {
    case menstrual
    case follicular
    case ovulation
    case luteal

    var nextType: PhaseType {
        switch self {
        case .menstrual: return .follicular
        case .follicular: return .ovulation
        case .ovulation: return .luteal
        case .luteal: return .menstrual
        }
    }
}
