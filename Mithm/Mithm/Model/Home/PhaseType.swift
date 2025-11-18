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
        case .menstrual: return "프로게스테론이 높아지면서 몸이 느려지고 부종·피곤함·감정 기복이 나타날 수 있어요"
        case .follicular: return "프로게스테론이 높아지면서 몸이 느려지고 부종·피곤함·감정 기복이 나타날 수 있어요"
        case .ovulation: return "프로게스테론이 높아지면서 몸이 느려지고 부종·피곤함·감정 기복이 나타날 수 있어요"
        case .luteal: return "프로게스테론이 높아지면서 몸이 느려지고 부종·피곤함·감정 기복이 나타날 수 있어요"
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
    
    var image: ImageResource {
        switch self {
        case .menstrual: return .menstrual
        case .follicular: return .follicular
        case .ovulation: return .ovulation
        case .luteal: return .luteal
        }
    }
}
