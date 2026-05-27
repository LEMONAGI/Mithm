//
//  HealthKitError.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation


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

    /// 기기 잠금 직후 보호된 HealthKit 데이터를 일시적으로 읽을 수 없음
    case protectedDataUnavailable

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

// MARK: - Alert Info

extension HealthKitError: AlertPresentable {
    var alertTitle: String {
        switch self {
        case .notAvailableOnDevice:
            return String(localized: "건강 앱을 사용할 수 없어요")
        case .authorizationNotDetermined, .authorizationDenied:
            return String(localized: "건강 앱 접근 권한이 필요해요")
        case .readFailed, .protectedDataUnavailable, .writeFailed, .deleteFailed:
            return String(localized: "건강 데이터 처리에 실패했어요")
        case .emptyResult:
            return String(localized: "월경 기록이 없어요")
        case .unknown:
            return String(localized: "알 수 없는 오류가 발생했어요")
        }
    }

    var alertMessage: String {
        switch self {
        case .notAvailableOnDevice:
            return String(localized: "이 기기에서는 건강 앱이 지원되지 않아요.")
        case .authorizationNotDetermined:
            return String(localized: "건강 앱 접근 범위를 확인해 주세요.")
        case .authorizationDenied:
            return String(localized: "설정 > 개인정보 보호 > 건강에서\n미리듬의 접근 권한을 확인해 주세요.")
        case .readFailed:
            return String(localized: "건강 데이터를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.")
        case .protectedDataUnavailable:
            return String(localized: "잠금 해제 후 잠시 뒤 다시 시도해 주세요.")
        case .writeFailed:
            return String(localized: "건강 데이터를 저장하지 못했어요.\n잠시 후 다시 시도해 주세요.")
        case .deleteFailed:
            return String(localized: "건강 데이터를 삭제하지 못했어요.\n잠시 후 다시 시도해 주세요.")
        case .emptyResult:
            return String(localized: "건강 앱에서 월경 기록을 추가하거나,\n설정 > 개인정보 보호 > 건강에서\n미리듬의 접근 권한을 확인해 주세요.")
        case .unknown:
            return String(localized: "잠시 후 다시 시도해 주세요.")
        }
    }
}

extension HealthKitError {
    var isTransientProtectedDataError: Bool {
        switch self {
        case .protectedDataUnavailable:
            return true
        default:
            return false
        }
    }
}
