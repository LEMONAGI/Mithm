//
//  FormatterUtility.swift
//  Mithm
//
//  Created by Codex on 8/13/25.
//

import Foundation

@MainActor
enum FormatterUtility {
    static let homePhaseRange: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = String(localized: "home.phase_range.date_format")
        return formatter
    }()

    static let homeNextMenstrual: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = String(localized: "home.next_menstrual.date_format")
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        ISO8601DateFormatter()
    }()
}
