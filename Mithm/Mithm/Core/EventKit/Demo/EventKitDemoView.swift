//
//  CalendarDebugView.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import SwiftUI
import EventKit

struct EventKitDemoView: View {
    
    @StateObject private var viewModel = EventKitDemoViewModel()
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                // MARK: - 권한 상태
                statusSection
                
                // MARK: - 동기화 정보
                if let last = viewModel.lastSyncedAt {
                    HStack {
                        Text("마지막 동기화:")
                        Text(last, style: .date)
                        Text(last, style: .time)
                        Spacer()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                
                // MARK: - 버튼 영역
                buttonSection
                
                // MARK: - 에러 메시지
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // MARK: - 이벤트 리스트
                eventListSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("EventKit Demo")
        }
    }
    
    
    // MARK: - Subviews
    
    private var statusSection: some View {
        HStack {
            Text("캘린더 권한 상태:")
            Text(statusText)
                .bold()
                .foregroundStyle(statusColor)
            Spacer()
        }
        .font(.subheadline)
    }
    
    private var buttonSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Button {
                    viewModel.requestAccess()
                } label: {
                    Text("권한 요청")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    viewModel.ensureCalendar()
                } label: {
                    Text("캘린더 확인/생성")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            HStack(spacing: 8) {
                Button {
                    viewModel.addDummyEvent()
                } label: {
                    if viewModel.isSyncing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("더미 이벤트 추가")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isSyncing)
                
                Button {
                    viewModel.refreshEvents()
                } label: {
                    Text("새로고침")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            Button(role: .destructive) {
                viewModel.deleteAllOurEvents()
            } label: {
                Text("모든 앱 이벤트 삭제")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isSyncing)
        }
    }
    
    private var eventListSection: some View {
        Group {
            if viewModel.events.isEmpty {
                Text("표시할 이벤트가 없어요.")
                    .foregroundStyle(.secondary)
            } else {
                List {
                    Section("앱 전용 캘린더 이벤트 (\(viewModel.events.count)개)") {
                        ForEach(viewModel.events, id: \.eventIdentifier) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title ?? "제목 없음")
                                    .font(.headline)
                                
                                Text("\(dateFormatter.string(from: event.startDate)) ~ \(dateFormatter.string(from: event.endDate))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                if let notes = event.notes {
                                    Text(notes)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if let url = event.url {
                                    Text(url.absoluteString)
                                        .font(.caption2)
                                        .foregroundStyle(.blue.opacity(0.7))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Helpers
    
    private var statusText: String {
        switch viewModel.authorizationStatus {
        case .notDetermined:    return "미요청"
        case .denied:           return "거부됨"
        case .restricted:       return "제한됨"
        case .fullAccess:       return "전체 접근 허용"
        case .writeOnly:        return "쓰기 전용"
        @unknown default:       return "알 수 없음"
        }
    }
    
    private var statusColor: Color {
        switch viewModel.authorizationStatus {
        case .fullAccess:       return .green
        case .notDetermined:    return .orange
        case .denied, .restricted: return .red
        case .writeOnly:        return .yellow
        @unknown default:       return .gray
        }
    }
}

#Preview {
    EventKitDemoView()
}
