//
//  OnboardingStep3View.swift
//  Mithm
//

import SwiftUI

struct OnboardingStep3View: View {

    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepContainer(
            step: .step3,
            title: "평소 월경 주기는\n얼마나 되나요?",
            description: "보통 28일을 기준으로 해요.\n본인의 주기를 알려주세요.",
            buttonTitle: "다음으로",
            isButtonEnabled: true,
            isLoading: false,
            onTapButton: { viewModel.advance() }
        ) {
            // TODO: 주기 선택 Slider/Picker 구현
        }
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    OnboardingStep3View()
        .environmentObject(graph.onboardingViewModel)
}
