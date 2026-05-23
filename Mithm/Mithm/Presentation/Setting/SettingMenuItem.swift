//
//  SettingMenuItem.swift
//  Mithm
//
//  Created by YunhakLee on 3/14/26.
//

import SwiftUI

enum SettingMenuItem: CaseIterable {
    case calendarExport
    case predictionMethod
    case cycleSetting
    case privacyPolicy
    case support

    var title: String {
        switch self {
        case .calendarExport: String(localized: "캘린더로 내보내기")
        case .predictionMethod: String(localized: "월경 주기 예측 방법 변경")
        case .cycleSetting: String(localized: "월경 주기·기간 변경")
        case .privacyPolicy: String(localized: "개인정보 처리방침")
        case .support: String(localized: "지원")
        }
    }

    var imageName: String {
        switch self {
        case .calendarExport: "Setting_Follicular"
        case .predictionMethod: "Setting_Luteal"
        case .cycleSetting: "Setting_Mirideum"
        case .privacyPolicy: "Setting_Ovulatory"
        case .support: "Setting_Menstrual"
        }
    }

    var accessoryType: SettingMenuAccessoryType {
        switch self {
        case .calendarExport: .toggle
        case .predictionMethod, .cycleSetting, .privacyPolicy, .support: .chevron
        }
    }

    var url: URL? {
        url(preferredLanguages: Locale.preferredLanguages)
    }

    func url(preferredLanguages: [String]) -> URL? {
        let usesKoreanURL = Self.usesKoreanURL(preferredLanguages: preferredLanguages)

        switch self {
        case .privacyPolicy:
            return URL(string: usesKoreanURL
                ? "https://jinthelemon.notion.site/2cc90636549f80cea5ebfbdd29671611?source=copy_link"
                : "https://jinthelemon.notion.site/Miridum-Privacy-Policy-35190636549f8094bd70cf6344efd3a1?source=copy_link")
        case .support:
            return URL(string: usesKoreanURL
                ? "https://jinthelemon.notion.site/2cc90636549f80999adace0a614b046d?source=copy_link"
                : "https://jinthelemon.notion.site/App-Support-Page-35190636549f80e69371f0f7dffcfa38?source=copy_link")
        default:
            return nil
        }
    }

    private static func usesKoreanURL(preferredLanguages: [String]) -> Bool {
        guard let firstLanguage = preferredLanguages.first else { return false }

        let normalizedLanguage = firstLanguage
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")

        return normalizedLanguage == "ko" || normalizedLanguage.hasPrefix("ko-")
    }
}

enum SettingMenuAccessoryType {
    case toggle
    case chevron
}
