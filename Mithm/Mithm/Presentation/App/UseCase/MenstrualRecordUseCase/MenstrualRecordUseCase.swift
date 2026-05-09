//
//  MenstrualRecordUseCase.swift
//  Mithm
//
//  Created by YunhakLee on 12/17/25.
//

import Foundation

protocol MenstrualRecordUseCase {
    func requestHealthKitAuthorization() async throws
    func fetchMenstrualOverview(
        activeMenstrualStartDate: Date?,
        userInput: MenstrualUserInput?,
        userInputMode: UserInputMode?
    ) async throws -> MenstrualOverview
    func saveMenstrualRecored(_ record: MenstrualRecord, deleteFrom: Date?, deleteThrough: Date?) async throws
    func deleteMenstrualRecord(from startDate: Date, to endDate: Date) async throws
}

extension MenstrualRecordUseCase {
    func fetchMenstrualOverview() async throws -> MenstrualOverview {
        try await fetchMenstrualOverview(
            activeMenstrualStartDate: nil,
            userInput: nil,
            userInputMode: nil
        )
    }

    func fetchMenstrualOverview(
        activeMenstrualStartDate: Date?
    ) async throws -> MenstrualOverview {
        try await fetchMenstrualOverview(
            activeMenstrualStartDate: activeMenstrualStartDate,
            userInput: nil,
            userInputMode: nil
        )
    }
}
