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
            description: "건강앱의 월경 기록을\n미리듬이 가져올 수 있게 허용해 주세요.\n몸의 기록은 안전하게 다룰게요.",
            buttonTitle: "권한 요청하기",
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
