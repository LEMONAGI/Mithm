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
    @State private var showMenstrualEndCompletionAlert = false
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
                    // Main image - fills available space
                    Image(homeViewModel.currentPhasePresentation.mainImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width)
                        .overlay(alignment: .topLeading) {
                            headerSection
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 20)
                                .padding(.top, 14)
                        }
                        .padding(.top, 14)
                    Spacer()
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    bottomSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 54)
                }
            }
        }
        .ignoresSafeArea(edges: .horizontal)
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
                .presentationDetents([.medium])
        }
        .alert(
            "이번 월경을 기록하였습니다",
            isPresented: $showMenstrualEndCompletionAlert
        ) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("내일부터 난포기가 시작됩니다.")
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
                Text(homeViewModel.currentPhasePresentation.name)
                    .font(.highlight1)
                    .foregroundStyle(.primaryBlack)
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.gray)
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
            Text(homeViewModel.showsMenstrualEndAction ? "월경 종료" : "월경 시작")
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
            Text(isPickingEndDate ? "월경 종료일을 선택하세요" : "월경 시작일을 선택하세요")
                .font(.pretendardBold(24))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 16)
            
            DatePicker(
                "",
                selection: $selectedDate,
                in: homeViewModel.selectableDateRange(isPickingEndDate: isPickingEndDate),
                displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                showDatePicker = false
                Task {
                    if isPickingEndDate {
                        let didRecord = await homeViewModel.endMenstruation(endDate: selectedDate)
                        if didRecord {
                            await MainActor.run {
                                showMenstrualEndCompletionAlert = true
                            }
                        }
                    } else {
                        await homeViewModel.startMenstruation(startDate: selectedDate)
                    }
                }
            } label: {
                Text("선택 완료")
                    .font(.pretendardBold(20))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.primaryBlack)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Preview

#Preview {
    let appState = AppDIContainer.makeAppState()
    HomeView()
        .environmentObject(AppDIContainer.makeHomeViewModel(appState: appState))
}
