//
//  HealthKitError.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//


enum HealthKitError: Error {

    // MARK: - Authorization

    /// HealthKit 자체가 지원되지 않는 기기 (iPad 등)
    case notAvailableOnDevice

    /// 아직 권한 요청이 되지 않음 → UI에서 권한 요청 팝업을 띄워야 함
    case authorizationNotDetermined

    /// 유저가 건강앱 공유 권한을 명시적으로 거부함 → 설정 앱으로 안내 필요
    case authorizationDenied

    // MARK: - Data Operations

    /// 건강 데이터 읽기 실패
    case readFailed

    /// 건강 데이터 쓰기 실패
    case writeFailed

    /// 건강 데이터 삭제 실패
    case deleteFailed

    /// 권한 없음 or 기록 없음 -> 권한을 수정하거나 기록을 추가하도록 유도.
    case emptyResult

    // MARK: - Unknown

    /// 알 수 없는 에러 (콘솔에 원본 에러가 로깅됨)
    case unknown
}
