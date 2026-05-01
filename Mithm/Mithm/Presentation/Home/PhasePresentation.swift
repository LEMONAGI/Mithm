//
//  PhasePresentation.swift
//  Mithm
//

import SwiftUI

struct PhasePresentation {
    let name: String
    let color: Color
    let description: String
    let mainImage: ImageResource
}

extension PhaseType {
    var presentation: PhasePresentation {
        switch self {
        case .menstrual:
            return PhasePresentation(
                name: "월경기",
                color: .primaryYellow,
                description: "호르몬이 낮아지며 몸이 휴식 모드로 바뀌어요\n몸이 리듬을 가다듬으며 쉬어가요",
                mainImage: .mainMenstrual
            )
        case .follicular:
            return PhasePresentation(
                name: "난포기",
                color: .primaryBlue,
                description: "에스트로겐이 증가하며 에너지와 집중이 올라요\n전반적인 리듬이 부드럽게 올라와요",
                mainImage: .mainFollicular
            )
        case .ovulation:
            return PhasePresentation(
                name: "배란기",
                color: .primaryTeal,
                description: "에스트로겐이 최고조로 컨디션이 안정돼요\n몸의 리듬이 안정적으로 맞물려요",
                mainImage: .mainOvulatory
            )
        case .luteal:
            return PhasePresentation(
                name: "황체기",
                color: .primaryPurple,
                description: "프로게스테론이 높아지며 몸이 회복을 준비해요\n리듬이 정리되며 몸이 쉬어갈 준비를 해요",
                mainImage: .mainLuteal
            )
        }
    }
}
