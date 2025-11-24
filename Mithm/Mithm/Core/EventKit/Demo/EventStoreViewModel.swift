////
////  EventStoreViewModel.swift
////  Mithm
////
////  Created by YunhakLee on 11/19/25.
////
//
//import Foundation
//import EventKit
//import Combine
//
//@MainActor
//final class EventStoreViewModel: ObservableObject {
//    
//    @Published var authorizationStatus: EKAuthorizationStatus
//    @Published var isSyncing: Bool = false
//    @Published var lastSyncedAt: Date?
//    @Published var errorMessage: String?
//    
//    private let dataStore: EventDataStore
//    
//    init(dataStore: EventDataStore = EventDataStore()) {
//        self.dataStore = dataStore
//        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
//    }
//    
//    var isAuthorized: Bool {
//        authorizationStatus == .fullAccess
//    }
//    
//    /// 권한 요청 + 상태 업데이트
//    func requestAccess() {
//        Task {
//            do {
//                let granted = try await dataStore.verifyAuthorizationStatus()
//                authorizationStatus = EKEventStore.authorizationStatus(for: .event)
//                
//                if !granted {
//                    errorMessage = "캘린더 전체 접근 권한이 허용되지 않았습니다."
//                }
//            } catch {
//                authorizationStatus = EKEventStore.authorizationStatus(for: .event)
//                errorMessage = "캘린더 권한을 가져오는 중 오류가 발생했어요."
//            }
//        }
//    }
//    
//    /// records 기반으로 전용 캘린더 전체 갈아끼우기
//    func sync(records: [CycleRecord]) {
//        guard !records.isEmpty else {
//            errorMessage = "동기화할 주기 데이터가 없습니다."
//            return
//        }
//        
//        Task {
//            isSyncing = true
//            defer { isSyncing = false }
//            
//            do {
//                // 권한 체크 (여기서도 한 번 더)
//                let granted = try await dataStore.verifyAuthorizationStatus()
//                authorizationStatus = EKEventStore.authorizationStatus(for: .event)
//                
//                guard granted, isAuthorized else {
//                    errorMessage = "캘린더 전체 접근 권한이 필요합니다."
//                    return
//                }
//                
//                try await dataStore.replaceAllEvents(with: records)
//                lastSyncedAt = Date()
//                
//            } catch let error as EventKitError {
//                switch error {
//                case .accessFail:
//                    errorMessage = "캘린더 권한이 없어서 동기화할 수 없습니다."
//                case .noSuitableSource:
//                    errorMessage = "캘린더를 생성할 수 있는 소스를 찾지 못했습니다."
//                case .eventCreationFail(let underlying):
//                    errorMessage = "이벤트 생성 중 오류가 발생했습니다: \(underlying.localizedDescription)"
//                }
//            } catch {
//                errorMessage = "캘린더 동기화 중 알 수 없는 오류가 발생했습니다."
//            }
//        }
//    }
//}
