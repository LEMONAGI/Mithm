//
//  MenstrualRecordUseCase.swift
//  Mithm
//
//  Created by YunhakLee on 12/17/25.
//

import Foundation

protocol MenstrualRecordUseCase {
    func requestHealthKitAuthorization() async throws
    func fetchMenstrualOverview() async throws -> MenstrualOverview
    func saveMenstrualRecored(_ record: MenstrualRecord, deleteFrom: Date?, deleteThrough: Date?) async throws
}
