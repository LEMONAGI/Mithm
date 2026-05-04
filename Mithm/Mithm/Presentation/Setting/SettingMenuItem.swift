//
//  SettingMenuItem.swift
//  Mithm
//
//  Created by YunhakLee on 3/14/26.
//

import SwiftUI

enum SettingMenuItem: CaseIterable {
    case healthSync
    case calendarExport
    case cycleSetting
    case privacyPolicy
    case support

    var title: String {
        switch self {
        case .healthSync: String(localized: "건강앱과 연동하기")
        case .calendarExport: String(localized: "캘린더로 내보내기")
        case .cycleSetting: String(localized: "월경 주기·길이 변경")
        case .privacyPolicy: String(localized: "개인정보 처리방침")
        case .support: String(localized: "지원")
        }
    }

    var imageName: String {
        switch self {
        case .healthSync: "Setting_Menstrual"
        case .calendarExport: "Setting_Follicular"
        case .cycleSetting: "Setting_Mirideum"
        case .privacyPolicy: "Setting_Ovulatory"
        case .support: "Setting_Luteal"
        }
    }

    var accessoryType: SettingMenuAccessoryType {
        switch self {
        case .healthSync, .calendarExport: .toggle
        case .cycleSetting, .privacyPolicy, .support: .chevron
        }
    }
}

enum SettingMenuAccessoryType {
    case toggle
    case chevron
}
