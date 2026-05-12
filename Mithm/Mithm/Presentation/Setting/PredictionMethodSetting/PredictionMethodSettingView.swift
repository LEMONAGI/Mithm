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
        .navigationTitle("예측 방법")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm) {
                    settingViewModel.savePredictionMethodDraft()
                    dismiss()
                }
            }
        }
        .onAppear {
            settingViewModel.resetPredictionMethodDraft()
        }
    }
}

private struct PredictionMethodSlider: View {

    @Binding var selection: UserInputMode

    private let trackHeight: CGFloat = 5
    private let thumbWidth: CGFloat = 38
    private let thumbHeight: CGFloat = 30

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                ForEach(UserInputMode.predictionMethodOptions, id: \.self) { mode in
                    Text(mode.displayTitle)
                        .font(.pretendardSemiBold(12))
                        .foregroundStyle(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            GeometryReader { geometry in
                let availableWidth = max(geometry.size.width - thumbWidth, 0)
                let xOffset = CGFloat(selection.sliderIndex) / 2 * availableWidth

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primaryOrange)
                        .frame(height: trackHeight)
                        .padding(.horizontal, thumbWidth / 2)

                    Capsule()
                        .fill(Color.primaryWhite)
                        .frame(width: thumbWidth, height: thumbHeight)
                        .shadow(color: .primaryBlack.opacity(0.15), radius: 6, x: 0, y: 2)
                        .offset(x: xOffset)
                        .animation(.easeInOut(duration: 0.18), value: selection)
                }
                .frame(height: thumbHeight)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateSelection(
                                locationX: value.location.x,
                                width: geometry.size.width
                            )
                        }
                )
            }
            .frame(height: thumbHeight)
        }
        .padding(.horizontal, 1)
        .padding(.top, 17)
        .padding(.bottom, 22)
        .background(Color.primaryWhite)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func updateSelection(locationX: CGFloat, width: CGFloat) {
        let availableWidth = max(width - thumbWidth, 1)
        let clampedX = min(max(locationX - thumbWidth / 2, 0), availableWidth)
        let index = Int((clampedX / availableWidth * 2).rounded())
        selection = UserInputMode.from(sliderIndex: Double(index))
    }
}

private extension UserInputMode {
    static let predictionMethodOptions: [UserInputMode] = [
        .notBlendUserInput,
        .blendUserInput,
        .onlyUserInput
    ]

    var displayTitle: String {
        switch self {
        case .onlyUserInput: "직접 입력값"
        case .blendUserInput: "둘 다 사용"
        case .notBlendUserInput: "기록 데이터"
        }
    }

    var displayDescription: String {
        switch self {
        case .onlyUserInput: "직접 입력한 주기와 기간만 사용해 예측해요."
        case .blendUserInput: "기록 데이터와 직접 입력값을 함께 반영해 예측해요."
        case .notBlendUserInput: "기록 데이터를 바탕으로 주기를 예측해요."
        }
    }

    var sliderIndex: Double {
        switch self {
        case .notBlendUserInput: 0
        case .blendUserInput: 1
        case .onlyUserInput: 2
        }
    }

    static func from(sliderIndex: Double) -> UserInputMode {
        switch Int(sliderIndex) {
        case 0: .notBlendUserInput
        case 2: .onlyUserInput
        default: .blendUserInput
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
