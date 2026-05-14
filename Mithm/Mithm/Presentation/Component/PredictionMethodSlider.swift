//
//  PredictionMethodSlider.swift
//  Mithm
//

import SwiftUI

struct PredictionMethodSlider: View {

    @Binding var selection: UserInputMode
    @State private var hapticTrigger = 0

    private let trackHeight: CGFloat = 6
    private let thumbWidth: CGFloat = 38
    private let thumbHeight: CGFloat = 24

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                predictionMethodLabel(for: .notBlendUserInput)
                Spacer(minLength: 24)
                predictionMethodLabel(for: .blendUserInput)
                Spacer(minLength: 24)
                predictionMethodLabel(for: .onlyUserInput)
            }
            .padding(.horizontal, 16)

            GeometryReader { geometry in
                let thumbInset = thumbWidth / 2
                let travelWidth = max(geometry.size.width - thumbWidth * 2, 0)
                let selectionRatio = CGFloat(selection.sliderIndex) / 2
                let xOffset = thumbInset + selectionRatio * travelWidth

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primaryOrange)
                        .frame(height: trackHeight)
                        .padding(.horizontal, thumbInset)

                    Capsule()
                        .fill(Color.primaryWhite)
                        .frame(width: thumbWidth, height: thumbHeight)
                        .shadow(color: .primaryBlack.opacity(0.12), radius: 12, x: 0, y: 6)
                        .shadow(color: .primaryBlack.opacity(0.12), radius: 4, x: 0, y: 0.5)
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
        .padding(.top, 16)
        .padding(.bottom, 23)
        .background(Color.primaryWhite)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .sensoryFeedback(.selection, trigger: hapticTrigger)
    }

    private func predictionMethodLabel(for mode: UserInputMode) -> some View {
        Text(mode.displayTitle)
            .font(.pretendardBold(12))
            .foregroundStyle(.textPrimary)
            .lineLimit(1)
    }

    private func updateSelection(locationX: CGFloat, width: CGFloat) {
        let thumbInset = thumbWidth / 2
        let travelWidth = max(width - thumbWidth * 2, 1)
        let minOffset = thumbInset
        let maxOffset = thumbInset + travelWidth
        let proposedOffset = locationX - thumbInset
        let clampedOffset = min(max(proposedOffset, minOffset), maxOffset)
        let index = Int(((clampedOffset - minOffset) / travelWidth * 2).rounded())
        let newSelection = UserInputMode.from(sliderIndex: Double(index))

        guard selection != newSelection else {
            return
        }

        selection = newSelection
        hapticTrigger += 1
    }
}

extension UserInputMode {
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
