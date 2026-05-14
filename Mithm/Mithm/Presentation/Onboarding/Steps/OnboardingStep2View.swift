//
//  OnboardingStep2View.swift
//  Mithm
//

import SwiftUI

struct OnboardingStep2View: View {

    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepContainer(
            step: .step2,
            title: "마지막 월경은\n언제 시작했나요?",
            description: "예측의 출발점이 되는 날짜예요.",
            buttonTitle: "다음으로",
            isButtonEnabled: true,
            isLoading: false,
            onTapButton: { viewModel.advance() }
        ) {
            // TODO: DatePicker 구현
        }
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    OnboardingStep2View()
        .environmentObject(graph.onboardingViewModel)
}
