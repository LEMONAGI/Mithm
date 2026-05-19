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
    }

    struct PermissionAlert: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
    }

    @Published var navigationPath: [Step] = []
    @Published var isRequestingAuthorization = false
    @Published var permissionAlert: PermissionAlert?

    // Step 2 - 마지막 월경 시작일/종료일
    @Published var lastPeriodStartDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var lastPeriodEndDate: Date = Calendar.current.startOfDay(for: Date())

    // Step 3 - 평소 월경 주기·길이
    @Published var averageCycleLength: Int = 28
    @Published var averagePeriodLength: Int = 5
    let cycleLengthRange = 21...45
    let periodLengthRange = 1...10

    // Step 4 - 월경 주기 예측 방법
    @Published var selectedPredictionMethod: UserInputMode = .notBlendUserInput

    // Step 5 - 완료 처리
    @Published var isFinishing = false

    var currentStep: Step {
        navigationPath.last ?? .step1
    }

    private let appState: AppState
    private let menstrualRecordUseCase: MenstrualRecordUseCase
    private let syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase

    init(
        appState: AppState,
        menstrualRecordUseCase: MenstrualRecordUseCase,
        syncMenstrualCalendarUseCase: SyncMenstrualCalendarUseCase
    ) {
        self.appState = appState
        self.menstrualRecordUseCase = menstrualRecordUseCase
        self.syncMenstrualCalendarUseCase = syncMenstrualCalendarUseCase
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

    func resetToDefaultCycleInput() {
        averageCycleLength = 28
        averagePeriodLength = 5
    }

    func requestCalendarAuthorization() async {
        guard !isFinishing else { return }
        isFinishing = true
        defer { isFinishing = false }
        do {
            try await saveAllData(calendarExportEnabled: true)
            await appState.completeOnboarding()
        } catch {
            permissionAlert = PermissionAlert(
                title: String(localized: "저장에 실패했어요"),
                message: String(localized: "건강 앱 권한을 확인하거나 잠시 후 다시 시도해 주세요.")
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
        guard !isFinishing else { return }
        guard let current = navigationPath.last, current.isLast else { return }
        isFinishing = true
        defer { isFinishing = false }
        do {
            try await saveAllData(calendarExportEnabled: false)
            await appState.completeOnboarding()
        } catch {
            permissionAlert = PermissionAlert(
                title: String(localized: "저장에 실패했어요"),
                message: String(localized: "건강 앱 권한을 확인하거나 잠시 후 다시 시도해 주세요.")
            )
        }
    }

    private func saveAllData(calendarExportEnabled: Bool) async throws {
        let record = MenstrualRecord(
            type: .menstrualRecord,
            startDate: lastPeriodStartDate,
            endDate: lastPeriodEndDate
        )
        try await menstrualRecordUseCase.saveMenstrualRecored(record, deleteFrom: nil, deleteThrough: nil)
        appState.saveMenstrualUserInput(MenstrualUserInput(cycleLength: averageCycleLength, periodLength: averagePeriodLength))
        appState.saveUserInputMode(selectedPredictionMethod)
        appState.saveCalendarExportEnabled(calendarExportEnabled)
    }

}
