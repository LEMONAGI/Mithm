//
//  HomeView.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @State private var showDatePicker = false
    @State private var showPhaseDetail = false
    @State private var menstrualEndCompletionAlertKind: HomeViewModel.EndMenstruationAlertKind?
    @State private var isPickingEndDate = false
    @State private var selectedDate = Date()
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                homeViewModel.currentPhasePresentation.color
                    .ignoresSafeArea()
                VStack {
                    Image(homeViewModel.currentPhasePresentation.mainImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width)
                    Spacer()
                }
                .ignoresSafeArea()
                
                VStack {
                    headerSection
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .padding(.top, 20)
                    
                    Spacer()
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    bottomSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
        }
        .ignoresSafeArea(edges: .horizontal)
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPhaseDetail) {
            PhaseDetailSheet(phase: homeViewModel.currentPhase)
                .presentationDragIndicator(.visible)
        }
        .alert(
            menstrualEndCompletionAlertTitle,
            isPresented: Binding(
                get: { menstrualEndCompletionAlertKind != nil },
                set: { isPresented in
                    if !isPresented {
                        menstrualEndCompletionAlertKind = nil
                    }
                }
            )
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            if let message = menstrualEndCompletionAlertMessage {
                Text(message)
            }
        }
    }
}

// MARK: - Subviews

private extension HomeView {
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("다음 월경 예정일")
                .font(.body5)
                .foregroundStyle(.primaryBlack)
            Text(homeViewModel.nextMenstrualString)
                .font(.heading4)
                .foregroundStyle(.primaryBlack)
        }
    }
    
    var bottomSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Phase date range
            Text(homeViewModel.currentPhaseDateRangeString)
                .font(.heading1)
                .foregroundStyle(.primaryBlack)
                .padding(.bottom, 4)
            
            // Phase name + info
            HStack(alignment: .bottom, spacing: 10) {
                Text(homeViewModel.currentPhasePresentation.homeTitleName)
                    .font(.highlight1)
                    .foregroundStyle(.primaryBlack)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .allowsTightening(true)
                    .layoutPriority(1)
                Button {
                    showPhaseDetail = true
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(homeViewModel.currentPhasePresentation.color, homeViewModel.currentPhase == .ovulation ? .accent : .gray)
                }
                .offset(y: -12)
            }
            .padding(.bottom, 10)
            
            // Description
            Text(homeViewModel.currentPhasePresentation.description)
                .font(.heading5)
                .foregroundStyle(.primaryBlack)
                .padding(.bottom, 26)
            
            // Action button
            actionButton
        }
    }
    
    var actionButton: some View {
        Button {
            if homeViewModel.showsMenstrualEndAction {
                isPickingEndDate = true
                selectedDate = Date()
            } else {
                isPickingEndDate = false
                selectedDate = Date()
            }
            showDatePicker = true
        } label: {
            Text(homeViewModel.showsMenstrualEndAction ? String(localized: "월경 종료") : String(localized: "월경 시작"))
                .font(.pretendardBold(30))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.primaryBlack)
                )
        }
    }
    
    var datePickerSheet: some View {
        VStack(spacing: 0) {
            Text(isPickingEndDate ? String(localized: "월경 종료일을 선택하세요") : String(localized: "월경 시작일을 선택하세요"))
                .font(.pretendardSemiBold(22))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 22)
                .padding(.bottom, 30)
            
            DatePicker(
                "",
                selection: $selectedDate,
                in: homeViewModel.selectableDateRange(isPickingEndDate: isPickingEndDate),
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding(.horizontal, 16)
            
            Spacer()
            
            Button {
                showDatePicker = false
                Task {
                    if isPickingEndDate {
                        let result = await homeViewModel.endMenstruation(endDate: selectedDate)
                        if let completionAlertKind = result.completionAlertKind {
                            await MainActor.run {
                                menstrualEndCompletionAlertKind = completionAlertKind
                            }
                        }
                    } else {
                        await homeViewModel.startMenstruation(startDate: selectedDate)
                    }
                }
            } label: {
                Text("선택 완료")
                    .font(.pretendardBold(18))
                    .foregroundStyle(.primaryWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.primaryBlack)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    var menstrualEndCompletionAlertTitle: String {
        switch menstrualEndCompletionAlertKind {
        case .endsToday:
            return String(localized: "이번 월경을 기록하였습니다")
        case .recorded:
            return String(localized: "월경이 기록되었습니다!")
        case nil:
            return ""
        }
    }

    var menstrualEndCompletionAlertMessage: String? {
        switch menstrualEndCompletionAlertKind {
        case .endsToday:
            return String(localized: "내일부터 난포기가 시작됩니다.")
        case .recorded, nil:
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    HomeView()
        .environmentObject(graph.appState)
        .environmentObject(graph.homeViewModel)
}
