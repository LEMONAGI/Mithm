//
//  OnboardingStep4View.swift
//  Mithm
//

import SwiftUI

struct OnboardingStep4View: View {

    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepContainer(
            step: .step4,
            title: "캘린더에\n기록을 남겨도 될까요?",
            description: "월경 예정일을 캘린더에\n자동으로 추가해 드려요.",
            buttonTitle: "캘린더 연동하기",
            isButtonEnabled: !viewModel.isRequestingCalendarAuthorization,
            isLoading: viewModel.isRequestingCalendarAuthorization,
            onTapButton: {
                Task { await viewModel.requestCalendarAuthorization() }
            }
        ) {
            // TODO: 캘린더 연동 설명 영역 구현
        }
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    OnboardingStep4View()
        .environmentObject(graph.onboardingViewModel)
}
