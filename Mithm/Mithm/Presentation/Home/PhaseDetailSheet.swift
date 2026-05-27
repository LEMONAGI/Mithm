//
//  PhaseDetailSheet.swift
//  Mithm
//

import SwiftUI

struct PhaseDetailSheet: View {
    let phase: PhaseType
    @State private var isWhyExpanded = false

    private var presentation: PhasePresentation { phase.presentation }
    private var detail: PhaseDetailContent { phase.detailContent }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.horizontal, 28)
                    .padding(.top, 44)
                    .padding(.bottom, phase == .ovulation ? 4 : 44)
                
                if phase == .ovulation {
                    ovulationWarningBanner
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
                contentSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
            }
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(presentation.tertiaryColor)
    }
}

// MARK: - Subviews

private extension PhaseDetailSheet {

    var ovulationWarningBanner: some View {
        HStack(alignment: .top, spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.accent)
                .font(.system(size: 15))
            Text(String(localized: "phase_detail.ovulation.warning"))
                .font(.pretendardSemiBold(10))
                .foregroundStyle(.gray350)
        }
    }

    var headerSection: some View {
        HStack(alignment: .center, spacing: 0) {
            Image(presentation.detailImage)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(presentation.name)
                    .font(.pretendardExtraBold(70))
                    .foregroundStyle(.primaryBlack)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(detail.subtitle)
                    .font(.pretendardSemiBold(18))
                    .foregroundStyle(.primaryBlack)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .minimumScaleFactor(0.6)
                    .padding(.trailing, 5)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    var contentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionGroup(title: String(localized: "phase_detail.section.body.title")) {
                detailCard(section: detail.bodySection)
            }
            .padding(.bottom, 20)
            sectionGroup(title: String(localized: "phase_detail.section.mood.title")) {
                moodCard
            }
            .padding(.bottom, 20)
            sectionGroup(title: String(localized: "phase_detail.section.tip.title")) {
                detailCard(section: detail.tipSection)
            }
            .padding(.bottom, 16)
            footerDisclaimer
        }
    }

    var footerDisclaimer: some View {
        Text(String(localized: "phase_detail.footer.disclaimer"))
            .font(.pretendardLight(12))
            .foregroundStyle(.textSecondary)
            .lineSpacing(2)
            .padding(.horizontal, 19)
    }

    func sectionGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.pretendardBold(18))
                .foregroundStyle(.primaryBlack)
                .padding(.horizontal, 16)
            content()
        }
    }

    func detailCard(section: PhaseDetailContent.BodySection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.description)
                .font(.pretendardRegular(14))
                .foregroundStyle(.primaryBlack)
                .lineSpacing(5)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(section.bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.pretendardRegular(14))
                            .foregroundStyle(.primaryBlack)
                        Text(bullet)
                            .font(.pretendardRegular(14))
                            .foregroundStyle(.primaryBlack)
                            .lineSpacing(5)
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.primaryWhite)
                .shadow(color: .buttonshadow, radius: 1, x: 0, y: 2)
        )
    }

    var moodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(detail.moodSection.description)
                .font(.pretendardRegular(14))
                .foregroundStyle(.primaryBlack)
                .lineSpacing(5)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(detail.moodSection.bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.pretendardRegular(14))
                            .foregroundStyle(.primaryBlack)
                        Text(bullet)
                            .font(.pretendardRegular(14))
                            .foregroundStyle(.primaryBlack)
                            .lineSpacing(5)
                    }
                }
            }
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isWhyExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(String(localized: "phase_detail.mood.why_button"))
                        .font(.pretendardBold(14))
                        .foregroundStyle(.primaryBlack)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.pretendardRegular(14))
                        .foregroundStyle(.primaryBlack.opacity(0.4))
                        .rotationEffect(.degrees(isWhyExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isWhyExpanded {
                Text(detail.whyContent)
                    .font(.pretendardRegular(14))
                    .foregroundStyle(.primaryBlack)
                    .lineSpacing(5)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.primaryWhite)
                .shadow(color: .buttonshadow, radius: 1, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    PhaseDetailSheet(phase: .luteal)
}
