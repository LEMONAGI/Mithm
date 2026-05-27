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
            title: "건강 앱의 월경 기록을\n연결해요",
            description: "미리듬은 월경 기록을 바탕으로\n주기와 캘린더 표시를 계산해요.\n다음 화면에서 공유할 항목을 직접 선택할 수 있어요.",
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
