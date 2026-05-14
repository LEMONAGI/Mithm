//
//  PredictionMethodSettingView.swift
//  Mithm
//

import SwiftUI

struct PredictionMethodSettingView: View {
    @EnvironmentObject private var settingViewModel: SettingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Text("앞으로의 예측을\n당신에게 맞게 조율할게요")
                .font(.pretendardBold(30))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 70)

            Text("월경 주기 예측 방법을 선택할 수 있어요.")
                .font(.pretendardRegular(18))
                .foregroundStyle(.textPrimary)

            Spacer().frame(height: 40)

            PredictionMethodSlider(
                selection: Binding(
                    get: { settingViewModel.predictionMethodDraft },
                    set: { settingViewModel.setPredictionMethodDraft($0) }
                )
            )
            .padding(.horizontal, 20)

            Spacer().frame(height: 40)

            Text(settingViewModel.predictionMethodDraft.displayDescription)
                .font(.pretendardLight(12))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.1), value: settingViewModel.predictionMethodDraft)

            Spacer()
        }
        .background(Color.secondaryPink.ignoresSafeArea())
        .navigationTitle("월경 주기 예측 방법 변경")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    settingViewModel.savePredictionMethodDraft()
                    dismiss()
                }
                .disabled(!settingViewModel.canSavePredictionMethodDraft)
            }
        }
        .onAppear {
            settingViewModel.resetPredictionMethodDraft()
        }
    }
}


#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    NavigationStack {
        PredictionMethodSettingView()
            .environmentObject(graph.settingViewModel)
    }
}
