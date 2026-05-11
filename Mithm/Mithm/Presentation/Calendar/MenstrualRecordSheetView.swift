//
//  MenstrualRecordSheetView.swift
//  Mithm
//

import SwiftUI

struct MenstrualRecordSheetView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var navigationPath: [MenstrualRecordRow] = []
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            MenstrualRecordListView(viewModel: viewModel)
                .navigationDestination(for: MenstrualRecordRow.self) { row in
                    MenstrualRecordEditView(
                        viewModel: viewModel,
                        row: row
                    )
                }
        }
    }
}

private struct MenstrualRecordListView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.menstrualRecordRows.isEmpty {
                    Text("표시할 월경 기록이 없어요.")
                        .font(.pretendardMedium(18))
                        .foregroundStyle(.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    VStack(spacing: 18) {
                        ForEach(viewModel.menstrualRecordRows) { row in
                            NavigationLink(value: row) {
                                MenstrualRecordRowView(row: row)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top, 30)
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Color.gray50.ignoresSafeArea())
        .navigationTitle("월경 기록")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct MenstrualRecordRowView: View {
    let row: MenstrualRecordRow
    
    var body: some View {
        HStack(spacing: 12) {
            Text(row.startDateText)
                .font(.pretendardRegular(18))
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            
            Spacer(minLength: 12)
            
            Text("\(row.cycleLengthText) · \(row.periodLengthText)")
                .font(.pretendardRegular(18))
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.textPrimary)
        }
        .frame(height: 52)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .buttonshadow, radius: 1, x: 0, y: 2)
        )
    }
}

private struct MenstrualRecordEditView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let row: MenstrualRecordRow
    
    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var showDeleteConfirmation = false
    @State private var showNotEditableAlert = false
    
    private let calendar = Calendar.current
    
    private static let dateLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy. M. d."
        return f
    }()
    
    init(
        viewModel: CalendarViewModel,
        row: MenstrualRecordRow
    ) {
        self.viewModel = viewModel
        self.row = row
        _startDate = State(initialValue: row.record.startDate)
        _endDate = State(initialValue: row.record.endDate ?? row.record.startDate)
    }
    
    var body: some View {
        ZStack {
            Color.gray50.ignoresSafeArea()
            
            VStack {
                dateForm
                    .padding(.top, 44)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                deleteButton
            }
        }
        .navigationTitle("월경 기록 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    guard row.record.isEditable else {
                        showNotEditableAlert = true
                        return
                    }
                    Task {
                        let didUpdate = await viewModel.updateMenstrualRecord(
                            row,
                            startDate: startDate,
                            endDate: endDate
                        )
                        if didUpdate {
                            dismiss()
                        }
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.glassProminent)
                .disabled(!isChanged)
            }
        }
        .tint(.accentColor)
        .onChange(of: startDate) {
            if startDate > endDate {
                endDate = startDate
            }
        }
        .alert("월경 기록을 삭제할까요?", isPresented: $showDeleteConfirmation) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                Task {
                    let didDelete = await viewModel.deleteMenstrualRecord(row)
                    if didDelete {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("삭제한 기록은 건강 앱에서도 지워집니다.")
        }
        .alert("수정할 수 없는 기록이에요", isPresented: $showNotEditableAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("미리듬 앱에서 생성하지 않은 월경 기록은 수정할 수 없어요.\n건강 앱에서 직접 수정해 주세요.")
        }
    }
    
    private var dateForm: some View {
        VStack(spacing: 0) {
            dateRow(
                title: "월경 시작일",
                selection: Binding(
                    get: { startDate },
                    set: { newValue in
                        startDate = calendar.startOfDay(for: newValue)
                    }
                ),
                range: Date.distantPast...min(endDate, today)
            )
            
            dateRow(
                title: "월경 종료일",
                selection: Binding(
                    get: { endDate },
                    set: { newValue in
                        endDate = calendar.startOfDay(for: newValue)
                    }
                ),
                range: startDate...today
            )
        }
        .frame(height: 104)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.white)
        )
        .overlay(alignment: .center) {
            Divider()
                .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private func dateRow(
        title: String,
        selection: Binding<Date>,
        range: ClosedRange<Date>
    ) -> some View {
        HStack {
            Text(title)
                .font(.pretendardRegular(18))
                .foregroundStyle(.textPrimary)
            
            Spacer()
            
            ZStack {
                // 1. 애플 기본 DatePicker(.compact) 스타일을 완벽하게 흉내 낸 가짜 UI
                Text(Self.dateLabelFormatter.string(from: selection.wrappedValue))
                    .font(.pretendardRegular(18))
                    .foregroundStyle(.textPrimary)
                    .monospacedDigit()
                    .frame(minWidth: 105, alignment: .center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemFill))
                    .cornerRadius(26)
                    .allowsHitTesting(false)
                
                DatePicker(
                    "",
                    selection: selection,
                    in: range,
                    displayedComponents: [.date]
                )
                .labelsHidden()
                .tint(.primaryOrange)
                .colorMultiply(.clear)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .padding(.horizontal, 16)
    }
    
    private var deleteButton: some View {
        Button {
            guard row.record.isEditable else {
                showNotEditableAlert = true
                return
            }
            showDeleteConfirmation = true
        } label: {
            Text("삭제하기")
                .font(.pretendardRegular(17))
                .foregroundStyle(.red)
                .padding(6)
        }
        .buttonStyle(.glass)
        .disabled(viewModel.isEditingMenstrualRecord)
    }
    
    private var isChanged: Bool {
        let originalStart = calendar.startOfDay(for: row.record.startDate)
        let originalEnd   = calendar.startOfDay(for: row.record.endDate ?? row.record.startDate)
        return startDate != originalStart || endDate != originalEnd
    }
    
    private var today: Date {
        calendar.startOfDay(for: Date())
    }
}


#Preview {
    let appState = AppDIContainer.makeAppState()
    MenstrualRecordSheetView(
        viewModel: AppDIContainer.makeCalendarViewModel(appState: appState)
    )
}
