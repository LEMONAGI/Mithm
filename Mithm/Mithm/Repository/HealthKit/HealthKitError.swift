//
//  HealthKitError.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//


enum HealthKitError: Error {
    
    // MARK: Authorization
    
    case notAvailableOnDevice                      // HealthKit 자체 지원 안 함
    case authorizationNotDetermined                // 아직 권한 요청 안 됨 (UI에서 팝업 띄울지 결정)
    case authorizationDenied                       // 유저가 명시적으로 거부함
    case authorizationRequestFailed(Error)         // requestAuthorization 호출 중 시스템 에러
    
    
    case invalidTypeForCategory     // 해당 타입이 Category로 불가능
    case invalidTypeForQuantity     // 해당 타입이 Quantity로 불가능
    case invalidTypeForSample       // 해당 타입이 Sample로 불가능
}
