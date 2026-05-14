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
            title: "앞으로의 예측을\n당신에게 맞게 조율할게요",
            description: "월경 주기 예측 방법을 선택할 수 있어요.",
            buttonTitle: "다음으로",
            isButtonEnabled: true,
            isLoading: false,
            onTapButton: {
                viewModel.advance()
            }
        ) {
            Spacer().frame(height: 40)
            
            PredictionMethodSlider(selection: $viewModel.selectedPredictionMethod)
                .padding(.horizontal, 20)

            Spacer().frame(height: 40)

            Text(viewModel.selectedPredictionMethod.displayDescription)
                .font(.pretendardLight(12))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.1), value: viewModel.selectedPredictionMethod)
        }
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    OnboardingStep4View()
        .environmentObject(graph.onboardingViewModel)
}
