//
//  OnboardingViewModel.swift
//  Mithm
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {

    enum Step: Int, CaseIterable {
        case step1 = 1
        case step2
        case step3
        case step4
        case step5

        var isLast: Bool {
            self == .step5
        }

        var backgroundColor: Color {
            switch self {
            case .step1: Color(.secondaryYellow)
            case .step2: Color(.secondaryTeal)
            case .step3: Color(.secondaryPink)
            case .step4: Color(.secondaryPurple)
            case .step5: Color(.secondaryBlue)
            }
        }

        var placeholderTitle: String {
            switch self {
            case .step1:
                return ""
            case .step2:
                return "두 번째 온보딩"
            case .step3:
                return "세 번째 온보딩"
            case .step4:
                return "네 번째 온보딩"
            case .step5:
                return "마지막 온보딩"
            }
        }
    }

    struct PermissionAlert: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
    }

    @Published var navigationPath: [Step] = []
    @Published var isRequestingAuthorization = false
    @Published var permissionAlert: PermissionAlert?

    private let appState: AppState
    private let menstrualRecordUseCase: MenstrualRecordUseCase

    init(
        appState: AppState,
        menstrualRecordUseCase: MenstrualRecordUseCase
    ) {
        self.appState = appState
        self.menstrualRecordUseCase = menstrualRecordUseCase
    }

    func requestHealthAuthorization() async {
        guard !isRequestingAuthorization else {
            return
        }

        isRequestingAuthorization = true
        defer {
            isRequestingAuthorization = false
        }

        do {
            try await menstrualRecordUseCase.requestConfirmedHealthKitAuthorization()
            navigationPath.append(.step2)
        } catch {
            permissionAlert = PermissionAlert(
                title: String(localized: "건강 앱 권한이 필요해요"),
                message: String(localized: "설정 > 개인정보 보호 및 보안 > 건강에서 활성화해 주세요. 권한을 허용해 주세요.")
            )
        }
    }

    func advance() {
        let current = navigationPath.last ?? .step1
        guard let nextStep = Step(rawValue: current.rawValue + 1) else {
            return
        }
        navigationPath.append(nextStep)
    }

    func finish() async {
        guard let current = navigationPath.last, current.isLast else {
            return
        }
        await appState.completeOnboarding()
    }
}
