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
        formatter.dateFormat = "M.dd"
        return formatter
    }()

    static let homeNextMenstrual: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        ISO8601DateFormatter()
    }()
}
