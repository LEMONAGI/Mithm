//
//  OnboardingStep5View.swift
//  Mithm
//

import SwiftUI

struct OnboardingStep5View: View {

    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepContainer(
            step: .step5,
            title: "당신의 리듬이\n일상에 연결될 수 있도록",
            description: "월경·배란 주기를 캘린더에 내보낼 수 있어요.\n한 번 연결하면, 이후 업데이트는\n미리듬이 알아서 관리할게요.",
            buttonTitle: "지금 내보내기",
            secondaryButtonTitle: "나중에 하기",
            isButtonEnabled: !viewModel.isFinishing,
            isLoading: viewModel.isFinishing,
            onTapButton: {
                Task { await viewModel.requestCalendarAuthorization() }
            },
            onTapSecondaryButton: {
                Task { await viewModel.finish() }
            }
        ) {
            // TODO: 캘린더 연동 설명 영역 구현
        }
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    OnboardingStep5View()
        .environmentObject(graph.onboardingViewModel)
}
