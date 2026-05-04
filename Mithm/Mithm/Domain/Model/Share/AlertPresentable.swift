//
//  AlertPresentable.swift
//  Mithm
//

import Foundation

/// 에러에 사용자용 alert 정보를 제공하는 프로토콜
protocol AlertPresentable: Error {
    var alertTitle: String { get }
    var alertMessage: String { get }
}

extension Error {
    /// AlertPresentable이면 해당 값을, 아니면 기본 메시지를 반환한다.
    var alertTitle: String {
        (self as? AlertPresentable)?.alertTitle ?? String(localized: "오류가 발생했어요")
    }

    var alertMessage: String {
        (self as? AlertPresentable)?.alertMessage ?? String(localized: "잠시 후 다시 시도해 주세요.")
    }
}
