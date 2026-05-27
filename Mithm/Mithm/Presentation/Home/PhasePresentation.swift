//
//  PhasePresentation.swift
//  Mithm
//

import SwiftUI

struct PhasePresentation {
    let name: String
    let homeTitleName: String
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
                homeTitleName: String(localized: "home.phase_title.menstrual"),
                color: .primaryYellow,
                tertiaryColor: .tertiaryYellow,
                description: String(localized: "모든 호르몬이 낮아지며 몸이 휴식 모드로 바뀌어요\n몸이 리듬을 가다듬으며 쉬어가요"),
                mainImage: .mainMenstrual,
                detailImage: .mainDetailMenstrual
            )
        case .follicular:
            return PhasePresentation(
                name: String(localized: "난포기"),
                homeTitleName: String(localized: "home.phase_title.follicular"),
                color: .primaryBlue,
                tertiaryColor: .tertiaryBlue,
                description: String(localized: "에스트로겐이 증가하며 에너지와 집중이 올라요\n전반적인 리듬이 부드럽게 올라와요"),
                mainImage: .mainFollicular,
                detailImage: .mainDetailFollicular
            )
        case .ovulation:
            return PhasePresentation(
                name: String(localized: "배란기"),
                homeTitleName: String(localized: "home.phase_title.ovulation"),
                color: .primaryTeal,
                tertiaryColor: .tertiaryTeal,
                description: String(localized: "에스트로겐이 최고조로 컨디션이 안정돼요\n몸의 리듬이 안정적으로 맞물려요"),
                mainImage: .mainOvulatory,
                detailImage: .mainDetailOvulatory
            )
        case .luteal:
            return PhasePresentation(
                name: String(localized: "황체기"),
                homeTitleName: String(localized: "home.phase_title.luteal"),
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
                subtitle: String(localized: "월경 시작 - 월경 종료"),
                bodySection: PhaseDetailContent.BodySection(
                    description: String(localized: "아랫배나 허리가 묵직하게 당기고, 평소보다 괜히 더 피곤한 느낌이 들 수 있어요. 몸이 무겁고 뭔가 하기 싫어지는 건 의지 문제가 아니라, 지금 몸이 꽤 많은 에너지를 쓰고 있기 때문이에요."),
                    bullets: [
                        String(localized: "복부·허리의 묵직한 통증"),
                        String(localized: "평소보다 쉽게 피로해지는 느낌"),
                        String(localized: "몸이 전반적으로 무겁게 느껴짐"),
                        String(localized: "체온이 낮고 손발이 차가울 수 있음")
                    ]
                ),
                moodSection: PhaseDetailContent.BodySection(
                    description: String(localized: "혼자 조용히 있고 싶거나, 별것 아닌 일에 예민하게 반응하게 되는 날이에요. 집중이 잘 안 되고, 감정이 쉽게 출렁이는 것도 자연스러운 반응이에요."),
                    bullets: [
                        String(localized: "집중력이 평소보다 떨어질 수 있어요"),
                        String(localized: "감정이 조금 더 예민하게 느껴져요"),
                        String(localized: "혼자만의 시간이 더 필요하게 느껴질 수 있어요")
                    ]
                ),
                whyContent: String(localized: "에스트로겐과 프로게스테론이 동시에 낮아지면서 자궁 내막이 탈락하고 월경이 시작됩니다. 이 호르몬들은 세로토닌(기분 안정), 도파민(동기·의욕)과도 연결되어 있어서, 수치가 낮아지면 기분이 가라앉거나 무기력함이 느껴질 수 있어요. 몸은 지금 새로운 주기를 준비하기 위해 꽤 많은 에너지를 쓰고 있는 중이에요."),
                tipSection: PhaseDetailContent.BodySection(
                    description: String(localized: "지금은 몸이 스스로 리셋하는 시기예요. 억지로 평소 페이스를 유지하려 하기보다, 조금 느슨하게 가는 것이 오히려 다음 주기를 잘 시작하는 방법이에요."),
                    bullets: [
                        String(localized: "중요한 결정이나 무거운 대화는 가능하면 며칠 뒤로 미뤄보세요."),
                        String(localized: "일정이 꽉 차 있다면 중간에 짧은 휴식을 의식적으로 끼워 넣어보세요."),
                        String(localized: "격한 운동보다는 가벼운 산책이나 스트레칭이 오히려 통증 완화에 도움이 돼요."),
                        String(localized: "따뜻한 음식, 충분한 수면, 핫팩 하나가 컨디션 차이를 만들어 줄 수 있어요."),
                        String(localized: "감정이 예민한 날이라는 걸 스스로 알고 있으면, 그 감정에 덜 휘둘릴 수 있어요.")
                    ]
                )
            )
        case .follicular:
            return PhaseDetailContent(
                subtitle: String(localized: "월경 끝난 직후 - 배란 직전"),
                bodySection: PhaseDetailContent.BodySection(
                    description: String(localized: "몸이 조금씩 가벼워지고, 피부가 맑아지는 느낌이 드는 시기예요. 월경이 끝나고 나서 \"오늘은 좀 살 것 같다\" 싶은 날들이 바로 난포기예요."),
                    bullets: [
                        String(localized: "피로가 줄고 몸이 가벼워지는 느낌"),
                        String(localized: "피부 컨디션이 좋아지기 시작함"),
                        String(localized: "폭식이나 특정 음식에 대한 갈망이 줄어들음"),
                        String(localized: "체력과 회복력이 올라가는 시기")
                    ]
                ),
                moodSection: PhaseDetailContent.BodySection(
                    description: String(localized: "점차 머리가 맑아지고, 뭔가 해보고 싶은 마음이 슬슬 생기는 시기예요. 새로운 걸 시작하거나 사람들을 만나는 게 부담스럽지 않고, 오히려 에너지가 느껴져요."),
                    bullets: [
                        String(localized: "호르몬의 영향으로 기분이 안정되고 긍정적인 감정이 올라와요"),
                        String(localized: "미뤄뒀던 일이나 새로운 도전에 대한 의욕이 생기는 시기예요"),
                        String(localized: "불안감이나 예민함이 줄어들어 마음이 한결 편안해져요")
                    ]
                ),
                whyContent: String(localized: "월경이 끝나갈 무렵 뇌하수체에서 분비되는 FSH(난포자극호르몬)가 난소 속 난포들을 성장시키기 시작해요. 이 난포들이 자라나면서 에스트로겐이라는 호르몬을 점점 더 많이 분비하게 됩니다. 에스트로겐은 자궁 내막을 다시 두껍게 준비시키는 역할도 하지만, 뇌 속 신경전달물질(세로토닌 등)의 활성을 도와 기분을 좋게 만들고 신체 피로를 빠르게 걷어내 줘요. 몸과 마음의 브레이크가 풀리며 서서히 에너지가 차오르는 상태가 되는 것이죠."),
                tipSection: PhaseDetailContent.BodySection(
                    description: String(localized: "몸과 마음의 에너지가 가장 균형 있게 돌아가는 시기예요. 그동안 미뤄뒀던 일들을 꺼내어 시작하거나 적극적인 활동을 계획하기에 가장 수월한 타이밍이랍니다."),
                    bullets: [
                        String(localized: "새로운 프로젝트나 공부를 시작하기 좋은 시기예요. 이 에너지가 있을 때 첫 발을 떼보세요."),
                        String(localized: "마음의 여유가 생기는 때라 사람들을 만나거나 협업하는 일이 평소보다 훨씬 자연스럽고 즐겁게 느껴질 거예요."),
                        String(localized: "운동을 새로 시작하거나 강도를 높이고 싶다면 지금이 적기예요. 회복도 빠른 편이에요."),
                        String(localized: "무너졌던 수면이나 식습관 루틴을 다시 탄탄하게 붙잡기에 몸도 마음도 가장 잘 도와주는 구간이에요.")
                    ]
                )
            )
        case .ovulation:
            return PhaseDetailContent(
                subtitle: String(localized: "배란일 전 - 배란 직후"),
                bodySection: PhaseDetailContent.BodySection(
                    description: String(localized: "전반적으로 몸의 컨디션이 좋고, 가볍게 잘 움직이는 느낌이 드는 시기예요. 에너지가 차올라 활력이 넘치지만, 간혹 아랫배 한쪽이 콕콕 찌르듯 당기는 느낌을 받기도 하는데 이는 자연스러운 “배란통”이랍니다."),
                    bullets: [
                        String(localized: "체력과 지구력이 한 주기 중 가장 높은 편"),
                        String(localized: "피부에 생기가 돌고 컨디션이 전반적으로 올라감"),
                        String(localized: "아랫배 한쪽이 잠깐 당기는 느낌(배란통)이 들 수 있음"),
                        String(localized: "배란 전후로 투명하고 끈적한 분비물(자궁경부 점액)이 늘어나는 것을 관찰할 수 있음")
                    ]
                ),
                moodSection: PhaseDetailContent.BodySection(
                    description: String(localized: "몸이 가벼워진 만큼 마음에도 긍정적인 활력과 생기가 도는 시기예요. 감정의 가라앉음이 덜하고 컨디션이 받쳐주다 보니, 평소보다 대화나 대인 활동을 할 때 조금 더 편안하고 자연스럽게 나를 표현할 수 있어요."),
                    bullets: [
                        String(localized: "호르몬이 정점에 달하며 활력과 긍정적인 에너지가 유지돼요"),
                        String(localized: "신체적 불편감이 적어 마음의 여유가 생기고 기분이 안정적인 편이에요"),
                        String(localized: "사람들과 소통하거나 내 의견을 표현하는 데 부담이 적고 편안함을 느껴요"),
                        String(localized: "무기력함이 걷히고 활동적인 일들을 적극적으로 해내고 싶은 마음이 들어요")
                    ]
                ),
                whyContent: String(localized: "난포기 동안 차곡차곡 쌓여온 에스트로겐 수치가 마침내 최고조에 달하면, 우리 뇌는 배란을 일으키는 핵심 신호인 LH(황체형성호르몬)를 급격하게 분비해요. 이 신호를 받아 성숙한 난자가 난소 밖으로 나오는 '배란'이 일어납니다. 이 시기는 한 주기 중 에스트로겐이 가장 정점을 찍는 때라, 몸과 마음에 활력을 주는 시너지 효과가 일어나요. 신체적 복원력과 기분을 안정시키는 호르몬들이 든든하게 받쳐주고 있기 때문에 가장 생기 있는 컨디션을 유지할 수 있는 것이죠."),
                tipSection: PhaseDetailContent.BodySection(
                    description: String(localized: "한 주기 중 신체적 활력이 가장 정점에 이르는 구간이에요. 나의 에너지를 외적으로 발산하거나 체력을 기르는 활동에 적극적으로 활용해 보세요."),
                    bullets: [
                        String(localized: "컨디션과 기분이 가장 안정적인 시기이므로 면접, 발표, 혹은 의견을 조율해야 하는 중요한 만남을 잡기에 아주 좋은 타이밍이에요."),
                        String(localized: "체력과 지구력이 가장 좋은 때입니다. 고강도 운동(러닝, 웨이트 등)에 도전해 보거나 평소보다 운동량을 조금 늘려보셔도 몸이 잘 따라와 줄 거예요."),
                        String(localized: "미뤄뒀던 야외 활동, 취미 생활, 혹은 에너지가 많이 드는 외부 일정을 이 시기에 배치하면 훨씬 수월하고 즐겁게 해낼 수 있어요."),
                        String(localized: "에너지가 넘친다고 해서 몸을 과도하게 무리해서 쓰기보다는, 곧 찾아올 황체기(생리 전 시기)를 고려해 기분 좋은 활력을 즐기며 적절한 휴식도 함께 챙겨주세요.")
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
