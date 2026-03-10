//
//  HealthKitDemoView.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import SwiftUI
import HealthKit

struct HealthKitDemoView: View {
    
    @StateObject private var viewModel = HealthKitDemoViewModel()
    @State private var newStartDate = Date()
    @State private var newEndDate = Date()
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
                
                // MARK: - 상태 표시
                statusSection
                
                // MARK: - 권한 & 새로고침 버튼
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
                
                // MARK: - 월경 기록 쓰기
                writeSection
                
                // MARK: - 에러
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // MARK: - 샘플 리스트
                sampleListSection
                
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("HealthKit Demo")
        }
    }
    
    
    // MARK: - Subviews
    
    private var statusSection: some View {
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
            
            Text("읽어온 샘플 수: \(viewModel.samples.count)개")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var writeSection: some View {
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
                    in: newStartDate...Date(),
                    displayedComponents: .date
                )
                
                Picker("월경 강도", selection: $selectedFlow) {
                    Text("가벼움").tag(HKCategoryValueVaginalBleeding.light)
                    Text("중간").tag(HKCategoryValueVaginalBleeding.medium)
                    Text("많음").tag(HKCategoryValueVaginalBleeding.heavy)
                    Text("불명확").tag(HKCategoryValueVaginalBleeding.unspecified)
                }
                .pickerStyle(.segmented)
                
                HStack(spacing: 8) {
                    Button {
                        viewModel.addMenstrualRecord(
                            startDate: newStartDate,
                            endDate: newEndDate,
                            flow: selectedFlow
                        )
                    } label: {
                        HStack {
                            if viewModel.isLoading { ProgressView() }
                            Text("저장")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                    
                    Button(role: .destructive) {
                        viewModel.deleteMenstrualRecord(
                            startDate: newStartDate,
                            endDate: newEndDate
                        )
                    } label: {
                        Text("해당 기간 삭제")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
    
    private var sampleListSection: some View {
        Group {
            if viewModel.samples.isEmpty {
                Text("표시할 월경 기록이 없어요.")
                    .foregroundStyle(.secondary)
            } else {
                List {
                    Section("월경 샘플 (HealthKit)") {
                        ForEach(viewModel.samples, id: \.uuid) { sample in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("menstrualFlow")
                                        .font(.headline)
                                    Spacer()
                                    if sample.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool == true {
                                        Text("주기 시작")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.red.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                Text("\(dateFormatter.string(from: sample.startDate)) ~ \(dateFormatter.string(from: sample.endDate))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text("value: \(sample.value)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    HealthKitDemoView()
}
