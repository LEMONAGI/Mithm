////
////  CycleSyncDemoView.swift
////  Mithm
////
////  Created by YunhakLee on 11/19/25.
////
//
//
//// CycleSyncDemoView.swift
//
//import SwiftUI
//
//struct CycleSyncDemoView: View {
//    
//    @StateObject private var viewModel = CycleSyncDemoViewModel()
//    
//    private let dateFormatter: DateFormatter = {
//        let f = DateFormatter()
//        f.dateStyle = .medium
//        f.timeStyle = .none
//        return f
//    }()
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 16) {
//                
//                // 설명
//                Text("HealthKit의 월경 기록을 불러와서\n전용 캘린더(미듬)에 내보내는 데모입니다.")
//                    .font(.subheadline)
//                    .multilineTextAlignment(.center)
//                    .foregroundStyle(.secondary)
//                
//                // 동기화 버튼
//                Button {
//                    viewModel.syncHealthToCalendar()
//                } label: {
//                    HStack {
//                        if viewModel.isSyncing {
//                            ProgressView()
//                        }
//                        Text("월경 기록 → 캘린더 동기화")
//                    }
//                    .frame(maxWidth: .infinity)
//                }
//                .buttonStyle(.borderedProminent)
//                .disabled(viewModel.isSyncing)
//                
//                // 상태 메시지
//                if let status = viewModel.statusMessage {
//                    Text(status)
//                        .font(.footnote)
//                        .foregroundStyle(.secondary)
//                        .multilineTextAlignment(.leading)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                }
//                
//                // 기록 리스트
//                if viewModel.records.isEmpty {
//                    Spacer()
//                    Text("아직 불러온 월경 기록이 없어요.\n버튼을 눌러 HealthKit에서 데이터를 가져와보세요.")
//                        .multilineTextAlignment(.center)
//                        .foregroundStyle(.secondary)
//                    Spacer()
//                } else {
//                    List {
//                        Section("HealthKit에서 가져온 월경 기록") {
//                            ForEach(viewModel.records) { record in
//                                VStack(alignment: .leading, spacing: 4) {
//                                    Text("월경 기록")
//                                        .font(.headline)
//                                    
//                                    Text("\(dateFormatter.string(from: record.startDate)) ~ \(dateFormatter.string(from: record.endDate))")
//                                        .font(.subheadline)
//                                    
//                                    let days = daysBetween(record.startDate, record.endDate) + 1
//                                    Text("총 \(days)일")
//                                        .font(.footnote)
//                                        .foregroundStyle(.secondary)
//                                }
//                                .padding(.vertical, 4)
//                            }
//                        }
//                    }
//                }
//                
//                Spacer(minLength: 0)
//            }
//            .padding()
//            .navigationTitle("Health → Calendar 데모")
//        }
//    }
//    
//    private func daysBetween(_ start: Date, _ end: Date) -> Int {
//        let cal = Calendar.current
//        let s = cal.startOfDay(for: start)
//        let e = cal.startOfDay(for: end)
//        let comp = cal.dateComponents([.day], from: s, to: e)
//        return comp.day ?? 0
//    }
//}
//
//#Preview {
//    CycleSyncDemoView()
//}
