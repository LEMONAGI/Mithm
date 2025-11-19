// HealthKitDemoViewModel.swift

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitDemoViewModel: ObservableObject {
    
    @Published var records: [CycleRecord] = []
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isAuthorized: Bool = false
    
    private let store = HealthKitCycleDataStore()
    
    /// 온보딩/처음 버튼 눌렀을 때 호출
    func requestAndLoad() {
        Task {
            await loadRecords(requestPermissionIfNeeded: true)
        }
    }
    
    /// 나중에 "새로고침" 버튼에서는 권한 요청 없이 그냥 읽기만
    func reload() {
        Task {
            await loadRecords(requestPermissionIfNeeded: false)
        }
    }
    
    private func loadRecords(requestPermissionIfNeeded: Bool) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if requestPermissionIfNeeded {
                try await store.verifyAuthorizationStatus()
            }
            isAuthorized = true
            
            let now = Date()
            // 예: 과거 1년 ~ 미래 1달
            let from = Calendar.current.date(byAdding: .year, value: -1, to: now)!
            let to   = Calendar.current.date(byAdding: .month, value: 1, to: now)!
            
            let fetched = try await store.fetchMenstrualRecords(from: from, to: to)
            records = fetched.sorted { $0.startDate < $1.startDate }
            lastSyncDate = Date()
            errorMessage = nil
            
        } catch let error as HealthKitError {
            handleHealthKitError(error)
            isAuthorized = false
        } catch {
            errorMessage = "HealthKit 데이터 로드 중 오류가 발생했습니다: \(error.localizedDescription)"
            isAuthorized = false
        }
    }
    
    // MARK: - 월경 기록 쓰기 (Health 앱에 저장)
    
    /// 데모용: 사용자가 선택한 시작/종료일을 Health 앱의 월경 데이터로 저장
    func addMenstrualRecord(
        startDate: Date,
        endDate: Date,
        flow: HKCategoryValueVaginalBleeding
    ) {
        Task {
            await addMenstrualRecordInternal(startDate: startDate, endDate: endDate, flow: flow)
        }
    }
    
    private func addMenstrualRecordInternal(
        startDate: Date,
        endDate: Date,
        flow: HKCategoryValueVaginalBleeding
    ) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 권한 확인 (요청 포함)
            try await store.verifyAuthorizationStatus()
            
            // Health 앱에 월경 샘플 저장
            try await store.saveMenstrualEpisode(
                startDate: startDate,
                endDate: endDate,
                flow: flow
            )
            
            // 방금 쓴 기록까지 포함해서 다시 읽어오기
            let now = Date()
            let from = Calendar.current.date(byAdding: .year, value: -1, to: now)!
            let to   = Calendar.current.date(byAdding: .month, value: 1, to: now)!
            
            let fetched = try await store.fetchMenstrualRecords(from: from, to: to)
            records = fetched.sorted { $0.startDate < $1.startDate }
            lastSyncDate = Date()
            errorMessage = nil    // 성공했으니 에러 메시지 제거
            
        } catch let error as HealthKitError {
            handleHealthKitError(error)
        } catch {
            errorMessage = "월경 기록 저장 중 오류가 발생했습니다: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 공통 에러 처리
    
    private func handleHealthKitError(_ error: HealthKitError) {
        switch error {
        case .notAvailableOnDevice:
            errorMessage = "이 기기에서는 건강 앱/HealthKit을 사용할 수 없어요."
        case .authorizationDenied:
            errorMessage = "건강 앱 접근 권한이 거부되었습니다. 설정 앱에서 권한을 다시 허용해주세요."
        case .missingType:
            errorMessage = "HealthKit에 요청한 항목이 응답에 포함되지 않았습니다."
        case .noSharingPermission:
            errorMessage = "해당 데이터를 공유하도록 허용하지 않은 상태입니다. 건강 앱 권한 설정을 확인해주세요."
        }
    }
}
