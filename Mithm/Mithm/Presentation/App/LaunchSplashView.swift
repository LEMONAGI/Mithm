//
//  LaunchSplashView.swift
//  Mithm
//
//  Created by Codex on 5/13/26.
//

import SwiftUI

struct LaunchSplashView: View {
    private let headlineText = """
    나의 리듬을 이해하고
    꼭 맞는 일정으로
    더 평온하고
    효율적인 하루를 살도록
    """

    private let noticeText = """
    미리듬이 제공하는 월경 주기, 배란일 및 관련 예측 정보는
    사용자의 월경 기록을 바탕으로 한 추정값입니다.
    실제 신체 상태 및 건강 상태와 다를 수 있으며,
    피임, 임신 계획 또는 건강 관련 의사결정의 근거로 단독 사용하지 마십시오.
    정확한 진단과 상담은 반드시 의료 전문가에게 받으시기 바랍니다.
    """

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    Image("LaunchImage")
                        .resizable()
                        .scaledToFit()
                        .clipped()
                        .ignoresSafeArea()
                }
                .ignoresSafeArea()

                Text("미리듬")
                    .font(.pretendardExtraBold(80))
                    .foregroundStyle(.primaryBlack)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 0.215
                    )

                Text(headlineText)
                    .font(.pretendardThin(18))
                    .foregroundStyle(.primaryBlack)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.82)
                    .frame(width: geometry.size.width * 0.82)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 0.375
                    )

                Text(noticeText)
                    .font(.pretendardSemiBold(10))
                    .foregroundStyle(.primaryBlack.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.74)
                    .frame(width: geometry.size.width * 0.84)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 0.915
                    )
            }
        }
        .ignoresSafeArea()
    }
        

    private func logoFontSize(for size: CGSize) -> CGFloat {
        min(size.width * 0.245, 92)
    }

    private func headlineFontSize(for size: CGSize) -> CGFloat {
        min(size.width * 0.073, 28)
    }

    private func noticeFontSize(for size: CGSize) -> CGFloat {
        min(size.width * 0.033, 13)
    }
}

#Preview {
    LaunchSplashView()
}
