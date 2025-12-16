////
////  CalendarDebugView.swift
////  Mithm
////
////  Created by YunhakLee on 11/19/25.
////
//
//import SwiftUI
//import EventKit
//
//struct CalendarDebugView: View {
//    
//    @StateObject private var viewModel = EventStoreViewModel()
//    @State private var records: [CycleRecord] = CycleRecordDummyFactory.makeDummyRecords()
//    
//    private var dateFormatter: DateFormatter {
//        let f = DateFormatter()
//        f.dateStyle = .medium
//        f.timeStyle = .none
//        return f
//    }
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 16) {
//                
//                // 권한 상태 표시
//                HStack {
//                    Text("캘린더 권한 상태:")
//                    Text(statusText)
//                        .bold()
//                        .foregroundStyle(statusColor)
//                    Spacer()
//                }
//                .font(.subheadline)
//                
//                if let last = viewModel.lastSyncedAt {
//                    HStack {
//                        Text("마지막 동기화:")
//                        Text(last, style: .date)
//                        Text(last, style: .time)
//                        Spacer()
//                    }
//                    .font(.footnote)
//                    .foregroundStyle(.secondary)
//                }
//                
//                // 더미 데이터 리스트
//                List {
//                    Section("더미 주기 데이터") {
//                        ForEach(records) { record in
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(record.type.title)
//                                    .font(.headline)
//                                
//                                Text("\(dateFormatter.string(from: record.startDate))  ~  \(dateFormatter.string(from: record.endDate))")
//                                    .font(.subheadline)
//                                    .foregroundStyle(.secondary)
//                                
//                                if let notes = record.type.notes {
//                                    Text(notes)
//                                        .font(.footnote)
//                                        .foregroundStyle(.secondary)
//                                }
//                            }
//                            .padding(.vertical, 4)
//                        }
//                    }
//                }
//                .frame(maxHeight: 320)
//                
//                // 버튼 영역
//                VStack(spacing: 12) {
//                    Button {
//                        viewModel.requestAccess()
//                    } label: {
//                        Text("캘린더 권한 요청")
//                            .frame(maxWidth: .infinity)
//                    }
//                    .buttonStyle(.borderedProminent)
//                    
//                    Button {
//                        viewModel.sync(records: records)
//                    } label: {
//                        if viewModel.isSyncing {
//                            ProgressView()
//                                .progressViewStyle(.circular)
//                                .frame(maxWidth: .infinity)
//                        } else {
//                            Text("전용 캘린더에 동기화")
//                                .frame(maxWidth: .infinity)
//                        }
//                    }
//                    .buttonStyle(.bordered)
//                    .disabled(viewModel.isSyncing)
//                }
//                
//                // 에러 메시지
//                if let error = viewModel.errorMessage {
//                    Text(error)
//                        .font(.footnote)
//                        .foregroundStyle(.red)
//                        .multilineTextAlignment(.leading)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                }
//                
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("캘린더 디버그")
//        }
//    }
//    
//    private var statusText: String {
//        switch viewModel.authorizationStatus {
//        case .notDetermined:
//            return "미요청"
//        case .denied:
//            return "거부됨"
//        case .restricted:
//            return "제한됨"
//        case .fullAccess:
//            return "전체 접근 허용"
//        case .writeOnly:
//            return "쓰기 전용"
//        @unknown default:
//            return "알 수 없음"
//        }
//    }
//    
//    private var statusColor: Color {
//        switch viewModel.authorizationStatus {
//        case .fullAccess:
//            return .green
//        case .notDetermined:
//            return .orange
//        case .denied, .restricted:
//            return .red
//        case .writeOnly:
//            return .yellow
//        @unknown default:
//            return .gray
//        }
//    }
//}
//
//#Preview {
//    CalendarDebugView()
//}
