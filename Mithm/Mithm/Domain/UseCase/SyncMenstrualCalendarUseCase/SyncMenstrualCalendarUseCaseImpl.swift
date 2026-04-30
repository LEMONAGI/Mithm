//
//  SyncMenstrualCalendarUseCaseImpl.swift
//  Mithm
//
//  Created by YunhakLee on 3/15/26.
//

import Foundation
import os

struct SyncMenstrualCalendarUseCaseImpl: SyncMenstrualCalendarUseCase {

    private let eventKitRepository: EventKitRepository
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.mithm",
        category: "SyncMenstrualCalendarUseCase"
    )

    init(eventKitRepository: EventKitRepository) {
        self.eventKitRepository = eventKitRepository
    }

    func execute(records: [MenstrualRecord], isEnabled: Bool) async throws {
        guard isEnabled else { return }

        let hasAccess = try await eventKitRepository.verifyCalendarAccess()
        guard hasAccess else { return }

        try await eventKitRepository.syncRecordsToCalendar(records)
    }
}
