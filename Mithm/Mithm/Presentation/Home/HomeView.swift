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

                VStack(spacing: 0) {
                    // Top header
                    headerSection
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // Main image - fills available space
                    Image(currentPhase.mainImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width)
                        .clipped()

                    // Bottom content
                    bottomSection
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 16)
                }
            }
        }
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
        .onChange(of: appState.menstrualRecord.loadState.isSettled) {
            checkEmptyRecords()
        }
    }
}

// MARK: - Subviews

private extension HomeView {

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("다음 월경 예정일")
                .font(.pretendardMedium(14))
                .foregroundStyle(.primaryBlack)
            Text(nextMenstrualString)
                .font(.pretendardBold(22))
                .foregroundStyle(.primaryBlack)
        }
    }

    var bottomSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Phase date range
            Text(currentPhaseDateRangeString)
                .font(.pretendardBold(20))
                .foregroundStyle(.primaryBlack)
                .padding(.bottom, 2)

            // Phase name + info
            HStack(alignment: .bottom, spacing: 4) {
                Text(currentPhase.name)
                    .font(.pretendardBlack(64))
                    .foregroundStyle(.primaryBlack)
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.gray)
                    .offset(y: -16)
            }
            .padding(.bottom, 4)

            // Description
            Text(currentPhase.description)
                .font(.pretendardSemiBold(16))
                .foregroundStyle(.primaryBlack)
                .lineSpacing(4)
                .padding(.bottom, 24)

            // Action button
            actionButton
        }
    }

    var actionButton: some View {
        Button {
            if isMenstruating {
                isPickingEndDate = true
            } else {
                isPickingEndDate = false
            }
            selectedDate = Date()
            showDatePicker = true
        } label: {
            Text(isMenstruating ? "월경 종료" : "월경 시작")
                .font(.pretendardBold(20))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 32)
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
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
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

// MARK: - Phase Logic

private extension HomeView {

    var loadedRecords: [MenstrualRecord] {
        if case .loaded(let records) = appState.menstrualRecord.loadState {
            return records
        }
        return []
    }

    var isMenstruating: Bool {
        !menstrualStartDateString.isEmpty
    }

    var currentPhase: PhaseType {
        let today = calendar.startOfDay(for: Date())

        // 사용자가 월경 시작 버튼을 눌러 진행 중인 경우
        if isMenstruating {
            return .menstrual
        }

        // 레코드가 없으면 기본값
        guard !loadedRecords.isEmpty else {
            return .luteal
        }

        // 레코드에서 오늘이 속한 구간 확인
        for record in loadedRecords {
            let start = calendar.startOfDay(for: record.startDate)
            let end = calendar.startOfDay(for: record.endDate ?? record.startDate)
            guard today >= start && today <= end else { continue }

            switch record.type {
            case .menstrualRecord, .menstrualPrediction:
                return .menstrual
            case .ovulationEstimated, .ovulationPrediction:
                return .ovulation
            case .ovulationFertileWindowEstimated, .ovulationFertileWindowPrediction:
                return .ovulation
            }
        }

        // 구간 사이에 있는 경우: 레코드를 시간순 정렬 후 직전/직후 레코드로 판단
        let sorted = loadedRecords.sorted { $0.startDate < $1.startDate }

        let menstrualRecords = sorted.filter {
            $0.type == .menstrualRecord || $0.type == .menstrualPrediction
        }
        let fertileRecords = sorted.filter {
            $0.type == .ovulationFertileWindowEstimated || $0.type == .ovulationFertileWindowPrediction
        }

        if let lastMenstrual = menstrualRecords.last(where: {
            calendar.startOfDay(for: $0.endDate ?? $0.startDate) < today
        }) {
            let menstrualEnd = calendar.startOfDay(for: lastMenstrual.endDate ?? lastMenstrual.startDate)
            if today > menstrualEnd {
                if let nextFertile = fertileRecords.first(where: {
                    calendar.startOfDay(for: $0.startDate) > today
                }) {
                    if today < calendar.startOfDay(for: nextFertile.startDate) {
                        return .follicular
                    }
                }
                if let nextMenstrual = menstrualRecords.first(where: {
                    calendar.startOfDay(for: $0.startDate) > today
                }) {
                    if today < calendar.startOfDay(for: nextMenstrual.startDate) {
                        return .luteal
                    }
                }
                return .follicular
            }
        }

        return .luteal
    }

    var currentPhaseDateRangeString: String {
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "M.dd"

        // 월경 진행 중
        if isMenstruating, let startDate = parseDateString(menstrualStartDateString) {
            return "\(formatter.string(from: startDate)) -"
        }

        // 레코드가 없으면 빈 문자열
        guard !loadedRecords.isEmpty else { return "" }

        // 오늘이 속한 레코드의 날짜 범위
        for record in loadedRecords {
            let start = calendar.startOfDay(for: record.startDate)
            let end = calendar.startOfDay(for: record.endDate ?? record.startDate)
            if today >= start && today <= end {
                return "\(formatter.string(from: record.startDate)) - \(formatter.string(from: record.endDate ?? record.startDate))"
            }
        }

        // 구간 사이: 직전 레코드 종료 ~ 직후 레코드 시작
        let sorted = loadedRecords.sorted { $0.startDate < $1.startDate }
        if sorted.count >= 2 {
            for i in 0..<(sorted.count - 1) {
                let currentEnd = calendar.startOfDay(for: sorted[i].endDate ?? sorted[i].startDate)
                let nextStart = calendar.startOfDay(for: sorted[i + 1].startDate)
                if today > currentEnd && today < nextStart {
                    if let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: sorted[i].endDate ?? sorted[i].startDate),
                       let dayBeforeNext = calendar.date(byAdding: .day, value: -1, to: sorted[i + 1].startDate) {
                        return "\(formatter.string(from: dayAfterEnd)) - \(formatter.string(from: dayBeforeNext))"
                    }
                }
            }
        }

        return ""
    }

    var nextMenstrualDate: Date? {
        let today = calendar.startOfDay(for: Date())
        return loadedRecords
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

    func checkEmptyRecords() {
        if case .loaded(let records) = appState.menstrualRecord.loadState {
            let actualRecords = records.filter { $0.type == .menstrualRecord }
            if actualRecords.isEmpty {
                showEmptyRecordsAlert = true
            }
        } else if case .failed = appState.menstrualRecord.loadState {
            showEmptyRecordsAlert = true
        }
    }
}

// MARK: - Actions

private extension HomeView {

    func startMenstruation(startDate: Date) {
        let formatter = ISO8601DateFormatter()
        menstrualStartDateString = formatter.string(from: startDate)
    }

    func endMenstruation(endDate: Date) async {
        guard let startDate = parseDateString(menstrualStartDateString) else { return }

        let record = MenstrualRecord(
            type: .menstrualRecord,
            startDate: startDate,
            endDate: endDate
        )

        do {
            try await appState.saveMenstrualRecord(record)
        } catch {
            // 에러는 AppState 내부에서 Logger로 처리
        }
        menstrualStartDateString = ""
    }

    func parseDateString(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}

// MARK: - LoadState Helper

extension LoadState {
    /// 로딩이 완료된 상태 (loaded 또는 failed)
    var isSettled: Bool {
        switch self {
        case .loaded, .failed: return true
        default: return false
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(AppDIContainer.makeAppState())
}
