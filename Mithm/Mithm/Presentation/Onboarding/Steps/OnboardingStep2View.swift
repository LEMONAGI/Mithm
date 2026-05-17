//
//  OnboardingStep2View.swift
//  Mithm

import SwiftUI

struct OnboardingStep2View: View {

    @EnvironmentObject private var viewModel: OnboardingViewModel

    private let calendar = Calendar.current

    var body: some View {
        OnboardingStepContainer(
            step: .step2,
            title: "당신의 리듬을 이해하는\n첫 단계예요",
            description: "마지막 월경 날짜는 언제인가요?",
            buttonTitle: "다음으로",
            isButtonEnabled: true,
            isLoading: false,
            onTapButton: {
                viewModel.advance()
            }
        ) {
            dateForm
                .padding(.top, 40)
                .padding(.horizontal, 20)
        }
        .onChange(of: viewModel.lastPeriodStartDate) {
            if viewModel.lastPeriodStartDate > viewModel.lastPeriodEndDate {
                viewModel.lastPeriodEndDate = viewModel.lastPeriodStartDate
            }
        }
    }

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    private var dateForm: some View {
        VStack(spacing: 0) {
            DatePicker(
                "월경 시작일",
                selection: Binding(
                    get: { viewModel.lastPeriodStartDate },
                    set: { viewModel.lastPeriodStartDate = calendar.startOfDay(for: $0) }
                ),
                in: Date.distantPast...min(viewModel.lastPeriodEndDate, today),
                displayedComponents: [.date]
            )
            .font(.pretendardRegular(17))
            .datePickerStyle(.compact)
            .tint(.accentColor)
            .frame(height: 52)
            .padding(.horizontal, 16)

            Divider()
                .padding(.horizontal, 16)

            DatePicker(
                "월경 종료일",
                selection: Binding(
                    get: { viewModel.lastPeriodEndDate },
                    set: { viewModel.lastPeriodEndDate = calendar.startOfDay(for: $0) }
                ),
                in: viewModel.lastPeriodStartDate...today,
                displayedComponents: [.date]
            )
            .font(.pretendardRegular(17))
            .datePickerStyle(.compact)
            .tint(.accentColor)
            .frame(height: 52)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 26).fill(Color.white))
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    OnboardingStep2View()
        .environmentObject(graph.onboardingViewModel)
}
