//
//  SyncMenstrualCalendarUseCaseImpl.swift
//  Mithm
//
//  Created by YunhakLee on 3/15/26.
//

import Foundation

struct SyncMenstrualCalendarUseCaseImpl: SyncMenstrualCalendarUseCase {

    private let eventKitRepository: EventKitRepository

    init(eventKitRepository: EventKitRepository) {
        self.eventKitRepository = eventKitRepository
    }

    func execute(records: [MenstrualRecord], isEnabled: Bool) async throws {
        guard isEnabled else { return }

        let hasAccess = try await eventKitRepository.verifyCalendarAccess()
        guard hasAccess else { return }

        try await eventKitRepository.syncRecordsToCalendar(records)
    }

    func removeCalendar() async throws {
        let hasAccess = try await eventKitRepository.verifyCalendarAccess()
        guard hasAccess else { return }
        try await eventKitRepository.removeCalendar()
    }
}
