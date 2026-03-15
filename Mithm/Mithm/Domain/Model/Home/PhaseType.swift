//
//  PeriodType.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI

enum PhaseType: Int, Hashable {
    case menstrual
    case follicular
    case ovulation
    case luteal
    
    var name: String {
        switch self {
        case .menstrual: return "월경기"
        case .follicular: return "난포기"
        case .ovulation: return "배란기"
        case .luteal: return "황체기"
        }
    }
    
    var color: Color {
        switch self {
        case .menstrual: return .mYellow
        case .follicular: return .mBlue
        case .ovulation: return .mTeal
        case .luteal: return .mPurple
        }
    }
    
    var description: String {
        switch self {
        case .menstrual:
            return "호르몬이 낮아지며 몸이 휴식 모드로 바뀌어요\n몸이 리듬을 가다듬으며 쉬어가요"
        case .follicular:
            return "에스트로겐이 증가하며 에너지와 집중이 올라요\n전반적인 리듬이 부드럽게 올라와요"
        case .ovulation:
            return "에스트로겐이 최고조로 컨디션이 안정돼요\n몸의 리듬이 안정적으로 맞물려요"
        case .luteal:
            return "프로게스테론이 높아지며 몸이 회복을 준비해요\n리듬이 정리되며 몸이 쉬어갈 준비를 해요"
        }
    }

    var nextType: PhaseType {
        switch self {
        case .menstrual: return .follicular
        case .follicular: return .ovulation
        case .ovulation: return .luteal
        case .luteal: return .menstrual
        }
    }

    var mainImage: ImageResource {
        switch self {
        case .menstrual: return .mainMenstrual
        case .follicular: return .mainFollicular
        case .ovulation: return .mainOvulatory
        case .luteal: return .mainLuteal
        }
    }

    var image: ImageResource {
        switch self {
        case .menstrual: return .menstrual
        case .follicular: return .follicular
        case .ovulation: return .ovulation
        case .luteal: return .luteal
        }
    }
}
