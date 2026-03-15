//
//  HomeView.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("menstrualStartDate") private var menstrualStartDateString: String = ""
    @State private var showDatePicker = false
    @State private var isPickingEndDate = false
    @State private var selectedDate = Date()
    @State private var showEmptyRecordsAlert = false
    
    private let calendar = Calendar.current
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                currentPhase.color
                    .ignoresSafeArea()
                VStack {
                    // Main image - fills available space
                    Image(currentPhase.mainImage)
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
        .alert("월경 기록이 없어요", isPresented: $showEmptyRecordsAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: "x-apple-health://") {
                    UIApplication.shared.open(url)
                }
            }
            Button("확인", role: .cancel) {}
        } message: {
            Text("건강 앱에서 월경 기록을 추가하거나,\n설정 > 개인정보 보호 > 건강에서\nMithm의 접근 권한을 확인해 주세요.")
        }
        .onChange(of: appState.menstrualRecordError != nil) {
            if appState.menstrualRecordError != nil {
                showEmptyRecordsAlert = true
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
            Text(nextMenstrualString)
                .font(.heading4)
                .foregroundStyle(.primaryBlack)
        }
    }
    
    var bottomSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Phase date range
            Text(currentPhaseDateRangeString)
                .font(.heading1)
                .foregroundStyle(.primaryBlack)
                .padding(.bottom, 4)
            
            // Phase name + info
            HStack(alignment: .bottom, spacing: 10) {
                Text(currentPhase.name)
                    .font(.highlight1)
                    .foregroundStyle(.primaryBlack)
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.gray)
                    .offset(y: -12)
            }
            .padding(.bottom, 10)
            
            // Description
            Text(currentPhase.description)
                .font(.heading5)
                .foregroundStyle(.primaryBlack)
                .padding(.bottom, 26)
            
            // Action button
            actionButton
        }
    }
    
    var actionButton: some View {
        Button {
            if isMenstruating {
                isPickingEndDate = true
                selectedDate = menstrualStartDate ?? Date()
            } else {
                isPickingEndDate = false
                selectedDate = Date()
            }
            showDatePicker = true
        } label: {
            Text(isMenstruating ? "월경 종료" : "월경 시작")
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
                in: selectableDateRange,
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
                        await endMenstruation(endDate: selectedDate)
                    } else {
                        startMenstruation(startDate: selectedDate)
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

// MARK: - ComputedValues

private extension HomeView {
    var allRecords: [MenstrualRecord] {
        appState.menstrualOverview.allRecords
    }

    var isMenstruating: Bool {
        !menstrualStartDateString.isEmpty
    }
    
    var currentPhase: PhaseType {
        currentPhaseWindow.phase
    }
    
    var currentPhaseDateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M.dd"
        return "\(formatter.string(from: currentPhaseWindow.startDate)) - \(formatter.string(from: currentPhaseWindow.endDate))"
    }
    
    var nextMenstrualDate: Date? {
        let today = calendar.startOfDay(for: Date())
        return allRecords
            .filter { $0.type == .menstrualPrediction || $0.type == .menstrualRecord }
            .sorted { $0.startDate < $1.startDate }
            .first { calendar.startOfDay(for: $0.startDate) > today }?
            .startDate
    }
    
    var nextMenstrualString: String {
        guard let nextDate = nextMenstrualDate else { return "-" }
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: nextDate)
        let days = calendar.dateComponents([.day], from: today, to: target).day ?? 0
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M월 d일"
        let dateStr = dateFormatter.string(from: nextDate)
        
        let dDay: String
        if days == 0 {
            dDay = "D-Day"
        } else if days > 0 {
            dDay = "D-\(days)"
        } else {
            dDay = "D+\(abs(days))"
        }
        
        return "\(dateStr) · \(dDay)"
    }

    var selectableDateRange: ClosedRange<Date> {
        let today = calendar.startOfDay(for: Date())

        if isPickingEndDate, let menstrualStartDate {
            return menstrualStartDate...today
        }

        return Date.distantPast...today
    }

    var menstrualStartDate: Date? {
        guard let date = parseDateString(menstrualStartDateString) else { return nil }
        return calendar.startOfDay(for: date)
    }

    var currentPhaseWindow: PhaseWindow {
        appState.makeCurrentPhaseWindow(
            activeMenstrualStartDate: menstrualStartDate
        )
    }
    
}

// MARK: - Actions

private extension HomeView {
    
    func startMenstruation(startDate: Date) {
        let formatter = ISO8601DateFormatter()
        menstrualStartDateString = formatter.string(from: calendar.startOfDay(for: startDate))
    }
    
    func endMenstruation(endDate: Date) async {
        guard let startDate = menstrualStartDate else { return }
        let normalizedEndDate = max(calendar.startOfDay(for: endDate), startDate)
        
        let record = MenstrualRecord(
            type: .menstrualRecord,
            startDate: startDate,
            endDate: normalizedEndDate
        )
        
        do {
            try await appState.saveMenstrualRecord(record)
            menstrualStartDateString = ""
        } catch {
            // 저장 실패 시 월경 시작 상태를 유지하여 데이터 손실 방지
        }
    }
    
    func parseDateString(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(AppDIContainer.makeAppState())
}
