//
//  MenstrualRecordUseCaseDemoView.swift
//  Mithm
//
//  Created by OpenAI on 3/11/26.
//

import SwiftUI

struct MenstrualRecordUseCaseDemoView: View {

    @StateObject private var viewModel = MenstrualRecordUseCaseDemoViewModel()
    @State private var startDate = Date()
    @State private var endDate = Date()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                statusSection
                actionSection
                saveSection

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                recordListSection
            }
            .padding()
            .navigationTitle("UseCase Demo")
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MenstrualRecordUseCase 상태")
                .font(.headline)

            if let lastLoadedAt = viewModel.lastLoadedAt {
                Text("마지막 로드: \(lastLoadedAt, style: .date) \(lastLoadedAt, style: .time)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let lastExportedAt = viewModel.lastExportedToCalendarAt {
                Text("마지막 캘린더 내보내기: \(lastExportedAt, style: .date) \(lastExportedAt, style: .time)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text("총 레코드 수: \(viewModel.records.count)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !viewModel.groupedCounts.isEmpty {
                ForEach(viewModel.groupedCounts, id: \.title) { item in
                    Text("\(item.title): \(item.count)개")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionSection: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.requestAuthorizationAndLoad()
            } label: {
                Text("권한 요청 + 조회 + 캘린더")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            Button {
                viewModel.reload()
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("다시 조회 + 캘린더")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading)
        }
    }

    private var saveSection: some View {
        GroupBox("실제 월경 기록 저장") {
            VStack(alignment: .leading, spacing: 8) {
                DatePicker(
                    "시작일",
                    selection: $startDate,
                    in: ...Date(),
                    displayedComponents: .date
                )

                DatePicker(
                    "종료일",
                    selection: $endDate,
                    in: ...Date(),
                    displayedComponents: .date
                )

                Button {
                    viewModel.saveRecord(startDate: startDate, endDate: endDate)
                } label: {
                    Text("기록 저장 후 조회 + 캘린더")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
        }
    }

    private var recordListSection: some View {
        List {
            Section("레코드") {
                if viewModel.records.isEmpty {
                    Text("표시할 레코드가 없어요.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(viewModel.records.enumerated()), id: \.offset) { _, record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.type.title)
                                .font(.headline)

                            Text("\(dateFormatter.string(from: record.startDate)) ~ \(dateFormatter.string(from: record.endDate ?? record.startDate))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(record.type.typeString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

#Preview {
    MenstrualRecordUseCaseDemoView()
}
