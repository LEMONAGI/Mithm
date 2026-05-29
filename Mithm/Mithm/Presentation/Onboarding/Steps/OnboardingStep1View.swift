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
            description: "미리듬의 주기 추적 기능을 이용하려면\nApple 건강 앱 연결이 필요해요.",
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
