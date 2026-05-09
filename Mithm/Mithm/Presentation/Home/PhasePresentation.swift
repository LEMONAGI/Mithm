//
//  PhasePresentation.swift
//  Mithm
//

import SwiftUI

struct PhasePresentation {
    let name: String
    let color: Color
    let tertiaryColor: Color
    let description: String
    let mainImage: ImageResource
    let detailImage: ImageResource
}

struct PhaseDetailContent {
    struct BodySection {
        let description: String
        let bullets: [String]
    }

    let subtitle: String
    let bodySection: BodySection
    let moodSection: BodySection
    let whyContent: String
    let tipSection: BodySection
}

extension PhaseType {
    var presentation: PhasePresentation {
        switch self {
        case .menstrual:
            return PhasePresentation(
                name: String(localized: "월경기"),
                color: .primaryYellow,
                tertiaryColor: .tertiaryYellow,
                description: String(localized: "호르몬이 낮아지며 몸이 휴식 모드로 바뀌어요\n몸이 리듬을 가다듬으며 쉬어가요"),
                mainImage: .mainMenstrual,
                detailImage: .mainDetailMenstrual
            )
        case .follicular:
            return PhasePresentation(
                name: String(localized: "난포기"),
                color: .primaryBlue,
                tertiaryColor: .tertiaryBlue,
                description: String(localized: "에스트로겐이 증가하며 에너지와 집중이 올라요\n전반적인 리듬이 부드럽게 올라와요"),
                mainImage: .mainFollicular,
                detailImage: .mainDetailFollicular
            )
        case .ovulation:
            return PhasePresentation(
                name: String(localized: "배란기"),
                color: .primaryTeal,
                tertiaryColor: .tertiaryTeal,
                description: String(localized: "에스트로겐이 최고조로 컨디션이 안정돼요\n몸의 리듬이 안정적으로 맞물려요"),
                mainImage: .mainOvulatory,
                detailImage: .mainDetailOvulatory
            )
        case .luteal:
            return PhasePresentation(
                name: String(localized: "황체기"),
                color: .primaryPurple,
                tertiaryColor: .tertiaryPurple,
                description: String(localized: "프로게스테론이 높아지며 몸이 회복을 준비해요\n리듬이 정리되며 몸이 쉬어갈 준비를 해요"),
                mainImage: .mainLuteal,
                detailImage: .mainDetailLuteal
            )
        }
    }

    var detailContent: PhaseDetailContent {
        switch self {
        case .menstrual:
            return PhaseDetailContent(
                subtitle: String(localized: "배란 직후 - 월경 시작"),
                bodySection: PhaseDetailContent.BodySection(
                    description: String(localized: "자궁 내막이 탈락하면서 몸이 무거워지는 시기예요. 호르몬이 급격히 낮아지면서 다양한 신체 증상이 나타날 수 있어요."),
                    bullets: [
                        String(localized: "복부와 허리에 통증이 느껴질 수 있어요"),
                        String(localized: "몸이 피로하고 에너지가 낮아요"),
                        String(localized: "두통이 동반되기도 해요"),
                        String(localized: "소화가 느려지거나 설사·변비가 생길 수 있어요"),
                        String(localized: "체온이 서서히 낮아지기 시작해요")
                    ]
                ),
                moodSection: PhaseDetailContent.BodySection(
                    description: String(localized: "호르몬이 낮아지면서 감정이 가라앉는 느낌이 들 수 있어요. 내향적이 되고 조용히 쉬고 싶은 시기예요."),
                    bullets: [
                        String(localized: "우울하거나 무기력한 기분이 들 수 있어요"),
                        String(localized: "감정이 차분해지고 내향적이 돼요"),
                        String(localized: "혼자만의 시간이 필요해질 수 있어요"),
                        String(localized: "작은 자극에도 피로감이 크게 느껴져요")
                    ]
                ),
                whyContent: String(localized: "월경은 에스트로겐과 프로게스테론이 모두 낮아지면서 시작해요. 자궁 내막이 탈락하는 과정에서 프로스타글란딘이 분비되어 경련과 통증을 유발할 수 있어요. 이 호르몬 저하는 세로토닌 수치에도 영향을 미쳐 기분 변화를 일으킬 수 있어요."),
                tipSection: PhaseDetailContent.BodySection(
                    description: String(localized: "월경기는 몸이 가장 많은 에너지를 소비하는 시기예요. 무리하지 않고 충분한 휴식을 취하는 것이 중요해요."),
                    bullets: [
                        String(localized: "충분한 수분과 철분이 풍부한 음식을 섭취하세요."),
                        String(localized: "격렬한 운동보다 가벼운 스트레칭이나 요가를 추천해요."),
                        String(localized: "따뜻한 찜질이 복통 완화에 효과적이에요."),
                        String(localized: "카페인과 알코올 섭취를 줄이는 것이 도움이 돼요."),
                        String(localized: "충분한 수면으로 몸이 회복할 시간을 주세요.")
                    ]
                )
            )
        case .follicular:
            return PhaseDetailContent(
                subtitle: String(localized: "월경 끝난 직후 - 배란 직전"),
                bodySection: PhaseDetailContent.BodySection(
                    description: String(localized: "에스트로겐이 증가하면서 몸이 가벼워지고 에너지가 올라오는 시기예요. 피부가 맑아지고 전반적인 컨디션이 좋아지는 것을 느낄 수 있어요."),
                    bullets: [
                        String(localized: "에너지가 점점 올라오는 것이 느껴져요"),
                        String(localized: "피부 상태가 맑아지고 윤기가 생겨요"),
                        String(localized: "체력이 좋아지고 활동하기 편해요"),
                        String(localized: "수면이 안정되고 개운한 느낌이에요"),
                        String(localized: "체온이 낮게 유지돼요")
                    ]
                ),
                moodSection: PhaseDetailContent.BodySection(
                    description: String(localized: "기분이 밝아지고 새로운 일에 도전하고 싶은 의욕이 생기는 시기예요. 집중력과 창의성이 올라와 생산적인 활동에 집중하기 좋아요."),
                    bullets: [
                        String(localized: "기분이 밝고 긍정적인 에너지가 높아요"),
                        String(localized: "집중력이 올라오고 학습 능력이 높아져요"),
                        String(localized: "새로운 것에 도전하고 싶은 의욕이 생겨요"),
                        String(localized: "사회적 교류가 즐겁고 소통이 활발해져요")
                    ]
                ),
                whyContent: String(localized: "뇌하수체에서 FSH(난포자극호르몬)가 분비되면서 난소의 난포가 성장하기 시작해요. 성장하는 난포에서 에스트로겐이 분비되면서 자궁 내막이 두꺼워지고 몸 전체가 활성화돼요. 에스트로겐은 세로토닌 분비를 촉진해 기분을 밝게 하고 집중력을 높여줘요."),
                tipSection: PhaseDetailContent.BodySection(
                    description: String(localized: "난포기는 에너지가 올라오는 시기인 만큼 새로운 계획을 세우고 실행하기 좋아요."),
                    bullets: [
                        String(localized: "새로운 프로젝트나 목표를 시작하기에 최적의 시기예요."),
                        String(localized: "사교 활동이나 중요한 미팅을 이 시기에 배치해보세요."),
                        String(localized: "유산소 운동이나 근력 운동 효과가 극대화되는 시기예요."),
                        String(localized: "창의적인 작업이나 브레인스토밍을 시도해보세요."),
                        String(localized: "새로운 식습관이나 루틴 변화를 시작하기 좋아요.")
                    ]
                )
            )
        case .ovulation:
            return PhaseDetailContent(
                subtitle: String(localized: "난포기 끝 - 배란 직후"),
                bodySection: PhaseDetailContent.BodySection(
                    description: String(localized: "에스트로겐이 최고조에 달하고 배란이 일어나는 시기예요. 컨디션이 최고조에 달해 몸이 가장 활기차고 기민한 상태예요."),
                    bullets: [
                        String(localized: "몸이 가장 가볍고 활기찬 느낌이에요"),
                        String(localized: "체력이 최고조로 에너지가 넘쳐요"),
                        String(localized: "피부가 가장 건강하고 빛나는 시기예요"),
                        String(localized: "목소리가 맑아지는 경우도 있어요"),
                        String(localized: "체온이 배란 직후 살짝 올라가요")
                    ]
                ),
                moodSection: PhaseDetailContent.BodySection(
                    description: String(localized: "자신감이 넘치고 사교적인 에너지가 최고조에 달하는 시기예요. 의사소통이 원활해지고 주변 사람들과 연결감을 강하게 느껴요."),
                    bullets: [
                        String(localized: "자신감이 높고 외향적인 에너지가 넘쳐요"),
                        String(localized: "의사소통이 원활하고 설득력이 높아져요"),
                        String(localized: "타인에 대한 공감 능력이 높아지는 시기예요"),
                        String(localized: "전반적으로 기분이 좋고 낙관적인 상태예요")
                    ]
                ),
                whyContent: String(localized: "에스트로겐이 최고조에 달하면 뇌하수체에서 LH(황체형성호르몬)가 급증해요. 이 LH 급증이 배란을 유발하고 난포에서 성숙한 난자가 방출돼요. 에스트로겐, 테스토스테론이 함께 높아지면서 신체적·정신적 에너지가 최고조에 달해요."),
                tipSection: PhaseDetailContent.BodySection(
                    description: String(localized: "배란기는 몸과 마음이 가장 활기찬 시기예요. 중요한 일에 에너지를 집중하세요."),
                    bullets: [
                        String(localized: "중요한 발표, 면접, 협상 등을 이 시기에 배치해보세요."),
                        String(localized: "고강도 운동이나 새로운 신체 도전을 시도하기 좋아요."),
                        String(localized: "소중한 사람들과의 만남이나 데이트를 계획해보세요."),
                        String(localized: "창의적 에너지를 활용해 프로젝트의 핵심 작업을 진행해보세요."),
                        String(localized: "이 활기를 기록해두면 다음 주기에 참고가 돼요.")
                    ]
                )
            )
        case .luteal:
            return PhaseDetailContent(
                subtitle: String(localized: "배란 직후 - 월경 시작 직전"),
                bodySection: PhaseDetailContent.BodySection(
                    description: String(localized: "몸이 조금씩 무거워지고, 붓거나 예민해지는 느낌이 드는 시기예요. 배란 이후 시간이 지날수록 증상이 강해지는 경우가 많고, 이건 매우 흔한 일이에요."),
                    bullets: [
                        String(localized: "몸이 붓고 무거운 느낌"),
                        String(localized: "가슴이 예민하거나 팽팽한 느낌"),
                        String(localized: "식욕이 늘거나 특정 음식이 당김"),
                        String(localized: "피부가 조금 거칠어질 수 있음"),
                        String(localized: "체온이 전 주기보다 높은 편")
                    ]
                ),
                moodSection: PhaseDetailContent.BodySection(
                    description: String(localized: "예민해지거나 이유 없이 우울한 기분이 드는 날이 생길 수 있어요. 집중이 잘 안 되거나 작은 일에 감정이 크게 반응하는 것도 이 시기엔 자연스러운 일이에요."),
                    bullets: [
                        String(localized: "감정 기복이 생기고 예민해지기 쉬워요"),
                        String(localized: "집중력이 흐트러지거나 멍해지는 느낌이 들 수 있어요"),
                        String(localized: "혼자 있고 싶거나, 쉬고 싶은 마음이 강해져요"),
                        String(localized: "불안하거나 이유 없이 울고 싶은 날이 있을 수 있어요")
                    ]
                ),
                whyContent: String(localized: "배란 후 황체에서 프로게스테론이 분비되기 시작해요. 프로게스테론은 자궁 내막을 안정시키는 역할을 하지만, 동시에 세로토닌 수치를 낮추고 GABA 수용체에 영향을 미쳐 기분 변화·불안·피로감을 유발할 수 있어요. 월경이 가까워질수록 에스트로겐과 프로게스테론이 모두 떨어지면서 PMS 증상이 나타나기 쉬운 구간이 돼요."),
                tipSection: PhaseDetailContent.BodySection(
                    description: String(localized: "황체기 후반은 몸이 스스로 속도를 줄이려는 시기예요. 이 신호를 무시하고 무리하기보다, 조금 다른 방식으로 생산성을 유지하는 전략이 더 잘 맞아요."),
                    bullets: [
                        String(localized: "새로운 걸 시작하기보다 이미 진행 중인 일을 마무리하는 데 집중해보세요."),
                        String(localized: "감정이 예민한 날엔 중요한 결정이나 감정이 오가는 대화를 미루는 것도 현명한 선택이에요."),
                        String(localized: "단것이 당기는 건 혈당 변동 때문이에요. 초콜릿 한 조각 정도는 괜찮지만, 폭식보다는 마그네슘·철분이 든 음식이 도움이 돼요."),
                        String(localized: "격한 운동보다 요가, 필라테스, 가벼운 걷기처럼 몸을 이완하는 활동이 증상 완화에 효과적이에요."),
                        String(localized: "\"내가 예민한 게 아니라 지금 호르몬이 이런 시기\"라는 걸 기억하는 것만으로도 감정을 다루는 데 도움이 돼요.")
                    ]
                )
            )
        }
    }
}
