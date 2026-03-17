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
        .task {
            await autoCloseOpenMenstruationIfNeeded()
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
                selectedDate = Date()
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
                        await startMenstruation(startDate: selectedDate)
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
        "\(FormatterUtility.homePhaseRange.string(from: currentPhaseWindow.startDate)) - \(FormatterUtility.homePhaseRange.string(from: currentPhaseWindow.endDate))"
    }
    
    var earliestPredictedMenstrualDate: Date? {
        let predictedRecords = allRecords.filter { $0.type == .menstrualPrediction }
        let targetIndex = isMenstruating ? 1 : 0

        guard predictedRecords.indices.contains(targetIndex) else { return nil }
        return predictedRecords[targetIndex].startDate
    }
    
    var nextMenstrualString: String {
        guard let nextDate = earliestPredictedMenstrualDate else { return "-" }
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: nextDate)
        let days = calendar.dateComponents([.day], from: today, to: target).day ?? 0
        
        let dateStr = FormatterUtility.homeNextMenstrual.string(from: nextDate)
        
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
    
    func startMenstruation(startDate: Date) async {
        let normalizedStart = calendar.startOfDay(for: startDate)
        menstrualStartDateString = FormatterUtility.iso8601.string(from: normalizedStart)

        // HealthKit에 진행 중인 월경(endDate nil) 저장
        let openRecord = MenstrualRecord(
            type: .menstrualRecord,
            startDate: normalizedStart,
            endDate: nil
        )
        do {
            try await appState.saveMenstrualRecord(openRecord)
        } catch {
            appState.menstrualRecordError = error
        }
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
            // 이전에 저장된 open record(startDate~오늘)까지 삭제 후 확정 기록 저장
            try await appState.saveMenstrualRecord(record, deleteThrough: Date())
            menstrualStartDateString = ""
        } catch {
            appState.menstrualRecordError = error
        }
    }
    
    func parseDateString(_ string: String) -> Date? {
        FormatterUtility.iso8601.date(from: string)
    }

    func autoCloseOpenMenstruationIfNeeded() async {
        do {
            let didAutoClose = try await appState.autoCloseOpenMenstruationIfNeeded(
                activeMenstrualStartDate: menstrualStartDate
            )
            if didAutoClose {
                menstrualStartDateString = ""
            }
        } catch {
            appState.menstrualRecordError = error
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(AppDIContainer.makeAppState())
}
