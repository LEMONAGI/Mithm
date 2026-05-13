//
//  CycleSettingView.swift
//  Mithm
//

import SwiftUI

struct CycleSettingView: View {

    @EnvironmentObject private var viewModel: CycleSettingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var expandedField: Field?

    private enum Field {
        case cycleLength, periodLength
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("당신만의 리듬 패턴을\n알려주세요")
                    .font(.pretendardBold(30))
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Spacer().frame(height: 70)

                Text("월경 주기와 길이는 몇일인가요?")
                    .font(.pretendardRegular(18))
                    .foregroundStyle(.textPrimary)

                Spacer().frame(height: 40)

                VStack(spacing: 0) {
                    InputRow(
                        label: "월경 주기",
                        value: viewModel.cycleLength,
                        isExpanded: expandedField == .cycleLength
                    ) {
                        withAnimation(.easeInOut(duration: 0.20)) {
                            expandedField = expandedField == .cycleLength ? nil : .cycleLength
                        }
                    }
                    if expandedField == .cycleLength {
                        Divider()
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                        inlinePicker(selection: $viewModel.cycleLength, range: viewModel.cycleLengthRange)
                            .transition(.opacity)
                    }
                    Divider()
                        .padding(.horizontal, 20)
                    InputRow(
                        label: "월경 길이",
                        value: viewModel.periodLength,
                        isExpanded: expandedField == .periodLength
                    ) {
                        withAnimation(.easeInOut(duration: 0.20)) {
                            expandedField = expandedField == .periodLength ? nil : .periodLength
                        }
                    }
                    if expandedField == .periodLength {
                        Divider()
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                        inlinePicker(selection: $viewModel.periodLength, range: viewModel.periodLengthRange)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.20), value: expandedField)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .padding(.horizontal, 20)
            }
        }
        .background(Color(.secondaryPink).ignoresSafeArea())
        .navigationTitle("월경 주기·길이 변경")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    viewModel.save()
                    dismiss()
                }
                .disabled(!viewModel.canSave)
            }
        }
        .onAppear {
            viewModel.reset()
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
        .frame(height: 180)
        .padding(.horizontal, 8)
    }
}

private struct InputRow: View {

    let label: String
    let value: Int
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.pretendardRegular(17))
                .foregroundStyle(.textPrimary)
            Spacer()
            Text("\(value)")
                .font(.pretendardRegular(17))
                .foregroundStyle(isExpanded ? Color.accentColor : Color(.textPrimary))
                .frame(width: 50)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .background(Color(UIColor.secondarySystemFill))
                .cornerRadius(30)
            Text("일")
                .font(.pretendardRegular(17))
                .foregroundStyle(.textPrimary)
        }
        .frame(height: 50)
        .padding(.horizontal, 30)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    NavigationStack {
        CycleSettingView()
            .environmentObject(graph.cycleSettingViewModel)
    }
}
