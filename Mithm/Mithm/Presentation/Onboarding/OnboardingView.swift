//
//  OnboardingView.swift
//  Mithm
//

import SwiftUI
import UIKit

struct OnboardingView: View {

    @EnvironmentObject private var viewModel: OnboardingViewModel

    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            healthPermissionStep
                .navigationDestination(for: OnboardingViewModel.Step.self) { step in
                    placeholderStep(step)
                }
        }
        .alert(item: $viewModel.permissionAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                primaryButton: .default(Text("설정으로 이동")) {
                    openAppSettings()
                },
                secondaryButton: .cancel(Text("확인"))
            )
        }
    }

    private var healthPermissionStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 108)

            Text("더 정확한\n리듬을 이해하기 위해")
                .font(.pretendardBold(34))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)

            Spacer().frame(height: 74)

            Text("건강앱의 월경 기록을\n미리듬이 가져올 수 있게 허용해 주세요.\n몸의 기록은 안전하게 다룰게요.")
                .font(.pretendardRegular(18))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()

            Button {
                Task {
                    await viewModel.requestHealthAuthorization()
                }
            } label: {
                HStack {
                    if viewModel.isRequestingAuthorization {
                        ProgressView()
                            .tint(.white)
                    }

                    Text("권한 요청하기")
                        .font(.pretendardBold(18))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(.primaryBlack))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .disabled(viewModel.isRequestingAuthorization)
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OnboardingViewModel.Step.step1.backgroundColor.ignoresSafeArea())
    }

    private func placeholderStep(_ step: OnboardingViewModel.Step) -> some View {
        VStack(spacing: 0) {
            Spacer()

            Text("\(step.rawValue) / \(OnboardingViewModel.Step.allCases.count)")
                .font(.pretendardSemiBold(18))
                .foregroundStyle(Color(.textPrimary).opacity(0.55))

            Spacer().frame(height: 28)

            Text(step.placeholderTitle)
                .font(.pretendardExtraBold(34))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                if step.isLast {
                    Task {
                        await viewModel.finish()
                    }
                } else {
                    viewModel.advance()
                }
            } label: {
                Text(step.isLast ? "시작하기" : "다음으로")
                    .font(.pretendardExtraBold(24))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color(.primaryBlack))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(step.backgroundColor.ignoresSafeArea())
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL)
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    OnboardingView()
        .environmentObject(graph.onboardingViewModel)
}
