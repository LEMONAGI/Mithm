//
//  OnboardingStep3View.swift
//  Mithm
//

import SwiftUI

struct OnboardingStep3View: View {

    @EnvironmentObject private var viewModel: OnboardingViewModel
    @State private var expandedField: Field?

    private enum Field {
        case cycleLength, periodLength
    }

    var body: some View {
        OnboardingStepContainer(
            step: .step3,
            title: "당신만의 리듬 패턴을\n알아갈게요",
            description: "월경 주기와 길이는 며칠인가요?",
            buttonTitle: "다음으로",
            isButtonEnabled: true,
            isLoading: false,
            onTapButton: { viewModel.advance() }
        ) {
            Spacer().frame(height: 40)

            VStack(spacing: 0) {
                CycleInputRow(
                    label: "월경 주기",
                    value: viewModel.averageCycleLength,
                    isExpanded: expandedField == .cycleLength
                ) {
                    withAnimation(.easeInOut(duration: 0.20)) {
                        expandedField = expandedField == .cycleLength ? nil : .cycleLength
                    }
                }
                if expandedField == .cycleLength {
                    Divider()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                }
                inlinePicker(selection: $viewModel.averageCycleLength, range: viewModel.cycleLengthRange)
                    .frame(height: expandedField == .cycleLength ? 180 : 0)
                    .clipped()
                Divider()
                    .padding(.horizontal, 16)
                CycleInputRow(
                    label: "월경 길이",
                    value: viewModel.averagePeriodLength,
                    isExpanded: expandedField == .periodLength
                ) {
                    withAnimation(.easeInOut(duration: 0.20)) {
                        expandedField = expandedField == .periodLength ? nil : .periodLength
                    }
                }
                if expandedField == .periodLength {
                    Divider()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                }
                inlinePicker(selection: $viewModel.averagePeriodLength, range: viewModel.periodLengthRange)
                    .frame(height: expandedField == .periodLength ? 180 : 0)
                    .clipped()
            }
            .animation(.easeInOut(duration: 0.20), value: expandedField)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .padding(.horizontal, 20)

            Spacer().frame(height: 20)

            Button {
                viewModel.resetToDefaultCycleInput()
            } label: {
                Text("잘 모르겠어요")
                    .font(.pretendardRegular(16))
                    .foregroundStyle(.textPrimary)
                    .overlay(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 26)
                            .frame(height: 1)
                            .foregroundStyle(.textPrimary)
                            .offset(y: 1)
                    }
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 12)

            Text("월경 주기와 길이를 모른다면 눌러주세요.\n미리듬이 우선 보편적 수치를 적용할게요.")
                .font(.pretendardLight(12))
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .onTapGesture {
            guard expandedField != nil else { return }
            withAnimation(.easeInOut(duration: 0.20)) {
                expandedField = nil
            }
        }
    }

    @ViewBuilder
    private func inlinePicker(selection: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Picker("", selection: selection) {
            ForEach(range, id: \.self) { value in
                Text("\(value)").tag(value)
            }
        }
        .pickerStyle(.wheel)
        .padding(.horizontal, 8)
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    OnboardingStep3View()
        .environmentObject(graph.onboardingViewModel)
}
