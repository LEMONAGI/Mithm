//
//  HealthKitDataStore.swift
//  Mithm
//
//  Created by YunhakLee on 11/20/25.
//

import Foundation
import HealthKit

/// HealthKit과 직접 통신하는 최하단 Data 레이어.
/// - 권한 요청, 읽기/쓰기, 삭제 등 모든 HealthKit 연산을 담당한다.
/// - Domain/UseCase에서는 HealthKit 타입(HKSampleType 등)을 직접 알지 않도록 하기 위해
///   Repository 단에서 Domain 타입 ↔︎ HealthKit 타입 매핑을 수행한다.
protocol HealthKitDataStore {
    
    // MARK: - Authorization
    
    /// 기기 자체가 HealthKit 기능을 지원하는지 여부.
    /// - 권한과는 무관한 capability 확인용.
    func isHealthDataAvailable() -> Bool
    
    /// HealthKit 읽기/쓰기 권한 요청.
    ///
    /// - 이 함수는 iOS가 제공하는 시스템 권한 팝업을 띄운다.
    /// - **사용자의 명시적 액션(버튼 탭 등)** 이후에만 호출해야 한다.
    /// - 실패 시 에러를 던지며, 성공 시 정상 종료한다.
    func requestAuthorization(
        writeTypes: Set<HKSampleType>,
        readTypes: Set<HKObjectType>
    ) async throws
    
    /// 특정 타입에 대한 **쓰기 권한 상태** 확인.
    ///
    /// - `.sharingAuthorized` / `.sharingDenied` / `.notDetermined` 반환.
    /// - HealthKit은 “읽기 권한”을 직접 제공하지 않기 때문에,
    ///   읽기 권한 여부는 readSamples 호출 시 빈 배열이 오는지로 간접 판단해야 한다.
    func checkWriteAuthorization(
        for type: HKObjectType
    ) -> HKAuthorizationStatus
    
    
    // MARK: - CRUD
    
    /// HealthKit에 샘플 저장.
    ///
    /// - **기존에 데이터가 있어도 덮어씌우므로, 중복되는 데이터를 방지하기 위해서는 해당 기간의 데이터를 삭제하고 저장해야 한다.**
    /// - 이 함수 호출 전 반드시 ‘쓰기 권한 확인’을 해야 한다.
    /// - 실패 시 에러가 던져지며, 성공 시 오류 없이 끝난다.
    func saveSamples(
        samples: [HKObject]
    ) async throws
    
    /// HealthKit에서 특정 기간의 카테고리 샘플 읽기.
    ///
    /// - 읽기 권한이 **없어도 에러가 나지 않으며**, 빈 배열이 반환된다.
    /// - 따라서 상위 레이어에서는 “데이터가 없거나, 건강 앱 공유 권한이 꺼져 있을 수 있습니다” 와 같은 UX가 필요하다.
    func readSamples(
        type: HKSampleType,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [HKCategorySample]
    
    /// 특정 날짜 구간에 걸치는 모든 기존 샘플 삭제.
    ///
    /// - 보통 새로운 샘플 저장 전에 호출된다.
    /// - 실패 시 에러, 성공 시 정상 종료.
    func deleteSamples(
        type: HKObjectType,
        from startDate: Date,
        to endDate: Date
    ) async throws
}
