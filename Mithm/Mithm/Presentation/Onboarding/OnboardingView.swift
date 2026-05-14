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
            OnboardingStep1View()
                .navigationDestination(for: OnboardingViewModel.Step.self) { step in
                    switch step {
                    case .step1: OnboardingStep1View()
                    case .step2: OnboardingStep2View()
                    case .step3: OnboardingStep3View()
                    case .step4: OnboardingStep4View()
                    case .step5: OnboardingStep5View()
                    }
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
