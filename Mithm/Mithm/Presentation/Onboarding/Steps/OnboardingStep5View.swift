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
            title: "이제 시작할\n준비가 됐어요!",
            description: "미리듬이 당신의 몸의 리듬을\n함께 기록할게요.",
            buttonTitle: "시작하기",
            isButtonEnabled: !viewModel.isFinishing,
            isLoading: viewModel.isFinishing,
            onTapButton: {
                Task { await viewModel.finish() }
            }
        ) {
            // TODO: 완료 일러스트/애니메이션 영역 구현
        }
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    OnboardingStep5View()
        .environmentObject(graph.onboardingViewModel)
}
