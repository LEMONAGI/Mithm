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
                .padding(.bottom, 14)
            sourceLinksSection
        }
    }

    var footerDisclaimer: some View {
        Text(String(localized: "phase_detail.footer.disclaimer"))
            .font(.pretendardLight(12))
            .foregroundStyle(.textSecondary)
            .lineSpacing(2)
            .padding(.horizontal, 19)
    }

    var sourceLinksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "phase_detail.sources.title"))
                .font(.pretendardSemiBold(12))
                .foregroundStyle(.textSecondary)
            SourceLinkFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(MedicalSourceLink.allCases, id: \.self) { source in
                    Link(destination: source.url) {
                        Text(source.title)
                            .font(.pretendardSemiBold(12))
                            .foregroundStyle(.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(Color.primaryWhite.opacity(0.72))
                            )
                    }
                }
            }
        }
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

private struct SourceLinkFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    init(horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let maxWidth = proposal.width ?? .greatestFiniteMagnitude
        let rows = makeRows(for: subviews, maxWidth: maxWidth)
        let height = rows.enumerated().reduce(CGFloat.zero) { total, row in
            total + row.element.size.height + (row.offset == 0 ? 0 : verticalSpacing)
        }

        return CGSize(width: proposal.width ?? rows.map(\.size.width).max() ?? 0, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let rows = makeRows(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX

            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: item.size.width, height: item.size.height)
                )
                x += item.size.width + horizontalSpacing
            }

            y += row.size.height + verticalSpacing
        }
    }

    private func makeRows(for subviews: Subviews, maxWidth: CGFloat) -> [SourceLinkFlowRow] {
        guard maxWidth > 0 else { return [] }

        var rows: [SourceLinkFlowRow] = []
        var currentItems: [SourceLinkFlowItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for index in subviews.indices {
            let measuredSize = subviews[index].sizeThatFits(.unspecified)
            let itemSize = CGSize(
                width: min(measuredSize.width, maxWidth),
                height: measuredSize.height
            )
            let nextWidth = currentItems.isEmpty
                ? itemSize.width
                : currentWidth + horizontalSpacing + itemSize.width

            if !currentItems.isEmpty, nextWidth > maxWidth {
                rows.append(
                    SourceLinkFlowRow(
                        items: currentItems,
                        size: CGSize(width: currentWidth, height: currentHeight)
                    )
                )
                currentItems = []
                currentWidth = 0
                currentHeight = 0
            }

            currentItems.append(SourceLinkFlowItem(index: index, size: itemSize))
            currentWidth = currentItems.count == 1
                ? itemSize.width
                : currentWidth + horizontalSpacing + itemSize.width
            currentHeight = max(currentHeight, itemSize.height)
        }

        if !currentItems.isEmpty {
            rows.append(
                SourceLinkFlowRow(
                    items: currentItems,
                    size: CGSize(width: currentWidth, height: currentHeight)
                )
            )
        }

        return rows
    }
}

private struct SourceLinkFlowRow {
    let items: [SourceLinkFlowItem]
    let size: CGSize
}

private struct SourceLinkFlowItem {
    let index: Int
    let size: CGSize
}

private enum MedicalSourceLink: CaseIterable {
    case officeOnWomensHealth
    case nichd
    case acogPMS
    case mayoCramps

    var title: String {
        switch self {
        case .officeOnWomensHealth:
            return String(localized: "phase_detail.sources.owh")
        case .nichd:
            return String(localized: "phase_detail.sources.nichd")
        case .acogPMS:
            return String(localized: "phase_detail.sources.acog_pms")
        case .mayoCramps:
            return String(localized: "phase_detail.sources.mayo_cramps")
        }
    }

    var url: URL {
        switch self {
        case .officeOnWomensHealth:
            return URL(string: "https://womenshealth.gov/menstrual-cycle")!
        case .nichd:
            return URL(string: "https://www.nichd.nih.gov/health/topics/factsheets/menstruation")!
        case .acogPMS:
            return URL(string: "https://www.acog.org/womens-health/faqs/premenstrual-syndrome")!
        case .mayoCramps:
            return URL(string: "https://www.mayoclinic.org/diseases-conditions/menstrual-cramps/diagnosis-treatment/drc-20374944")!
        }
    }
}

// MARK: - Preview

#Preview {
    PhaseDetailSheet(phase: .luteal)
}
