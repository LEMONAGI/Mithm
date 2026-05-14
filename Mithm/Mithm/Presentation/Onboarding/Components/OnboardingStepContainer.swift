//
//  OnboardingStepContainer.swift
//  Mithm
//

import SwiftUI

struct OnboardingStepContainer<Content: View>: View {

    let step: OnboardingViewModel.Step
    let title: String
    let description: String
    let buttonTitle: String
    let isButtonEnabled: Bool
    let isLoading: Bool
    let onTapButton: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: step == .step1 ? 108 : 56)

            Text(title)
                .font(.pretendardBold(34))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)

            Spacer().frame(height: 74)

            Text(description)
                .font(.pretendardRegular(18))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            content()

            Spacer()

            Button {
                onTapButton()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(buttonTitle)
                        .font(.pretendardBold(18))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(.primaryBlack))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .disabled(!isButtonEnabled)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(step.backgroundColor.ignoresSafeArea())
    }
}
