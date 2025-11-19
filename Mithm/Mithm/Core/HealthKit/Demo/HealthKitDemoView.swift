//
//  HealthKitDemoView.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//


// HealthKitDemoView.swift

import SwiftUI
import HealthKit

struct HealthKitDemoView: View {
    
    @StateObject private var viewModel = HealthKitDemoViewModel()
    @State private var newStartDate: Date = Date()
    @State private var newEndDate: Date = Date()
    @State private var selectedFlow: HKCategoryValueVaginalBleeding = .medium
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                // 권한 & 상태 영역
                VStack(alignment: .leading, spacing: 8) {
                    Text("HealthKit 상태")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(viewModel.isAuthorized ? .green : .red)
                        Text(viewModel.isAuthorized ? "권한 허용됨" : "권한 없음")
                            .font(.subheadline)
                    }
                    
                    if let last = viewModel.lastSyncDate {
                        Text("마지막 동기화: \(last, style: .date) \(last, style: .time)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 버튼
                HStack {
                    Button {
                        viewModel.requestAndLoad()
                    } label: {
                        Text("권한 요청 + 불러오기")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        viewModel.reload()
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("다시 불러오기")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                }
                
                // 🔻 여기부터 추가: 월경 기록 쓰기 데모 섹션
                GroupBox("월경 기록을 Health 앱에 추가") {
                    VStack(alignment: .leading, spacing: 8) {
                        DatePicker(
                            "시작일",
                            selection: $newStartDate,
                            in: ...Date(),
                            
                            displayedComponents: .date
                        )
                        
                        DatePicker(
                            "종료일",
                            selection: $newEndDate,
                            in: newStartDate...Date(),         // 시작일 이후만 선택 가능
                            displayedComponents: .date
                        )
                        
                        Picker("월경 강도", selection: $selectedFlow) {
                            Text("가벼움").tag(HKCategoryValueVaginalBleeding.light)
                            Text("중간").tag(HKCategoryValueVaginalBleeding.medium)
                            Text("많음").tag(HKCategoryValueVaginalBleeding.heavy)
                            Text("불명확").tag(HKCategoryValueVaginalBleeding.unspecified)
                        }
                        .pickerStyle(.segmented)
                        
                        Button {
                            viewModel.addMenstrualRecord(
                                startDate: newStartDate,
                                endDate: newEndDate,
                                flow: selectedFlow
                            )
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                }
                                Text("Health 앱에 월경 기록 저장")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading)
                    }
                }
                
                // 에러 메시지
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 기록 리스트
                if viewModel.records.isEmpty {
                    Spacer()
                    Text("표시할 월경 기록이 없어요.")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List {
                        Section("월경 기록 (HealthKit)") {
                            ForEach(viewModel.records) { record in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(record.type.title)
                                        .font(.headline)
                                    
                                    Text("\(dateFormatter.string(from: record.startDate))  ~  \(dateFormatter.string(from: record.endDate))")
                                        .font(.subheadline)
                                    
                                    let days = daysBetween(record.startDate, record.endDate) + 1
                                    Text("총 \(days)일")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("HealthKit Demo")
        }
    }
    
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let cal = Calendar.current
        let s = cal.startOfDay(for: start)
        let e = cal.startOfDay(for: end)
        let comp = cal.dateComponents([.day], from: s, to: e)
        return comp.day ?? 0
    }
}

#Preview {
    HealthKitDemoView()
}
