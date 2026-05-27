//
//  OnboardingStep1View.swift
//  Mithm
//

import SwiftUI

struct OnboardingStep1View: View {

    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepContainer(
            step: .step1,
            title: "더 정확한\n리듬을 이해하기 위해",
            description: "미리듬의 주기 추적 기능은\nApple 건강 앱의 월경 기록을 바탕으로 작동해요.",
            buttonTitle: "다음",
            isButtonEnabled: !viewModel.isRequestingAuthorization,
            isLoading: viewModel.isRequestingAuthorization,
            onTapButton: {
                Task {
                    await viewModel.requestHealthAuthorization()
                }
            }
        ) {
            EmptyView()
        }
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    OnboardingStep1View()
        .environmentObject(graph.onboardingViewModel)
}
