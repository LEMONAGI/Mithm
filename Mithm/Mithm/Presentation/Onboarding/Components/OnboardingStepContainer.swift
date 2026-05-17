//
//  OnboardingStepContainer.swift
//  Mithm
//

import SwiftUI

struct OnboardingStepContainer<Content: View>: View {

    let step: OnboardingViewModel.Step
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let buttonTitle: LocalizedStringKey
    var secondaryButtonTitle: LocalizedStringKey? = nil
    let isButtonEnabled: Bool
    let isLoading: Bool
    let onTapButton: () -> Void
    var onTapSecondaryButton: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: step == .step1 ? 68 : 16)

            Text(title)
                .font(.pretendardBold(34))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .lineSpacing(4)
                .padding(.horizontal, 24)
                .fixedSize()

            Spacer().frame(height: 50)

            Text(description)
                .font(.pretendardRegular(18))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            content()

            Spacer(minLength: 16)

            if let secondaryTitle = secondaryButtonTitle {
                HStack(spacing: 8) {
                    Button {
                        onTapSecondaryButton?()
                    } label: {
                        Text(secondaryTitle)
                            .font(.pretendardBold(18))
                            .foregroundStyle(Color(.primaryBlack))
                            .frame(width: 134)
                            .frame(height: 52)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(.primaryBlack), lineWidth: 1))
                    }

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
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            } else {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(step.backgroundColor.ignoresSafeArea())
    }
}
