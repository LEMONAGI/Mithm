//
//  MenstrualRecordEditingUseCase.swift
//  Mithm
//

import Foundation

protocol MenstrualRecordEditingUseCase {
    func update(
        originalRecord: MenstrualRecord,
        startDate: Date,
        endDate: Date
    ) async throws

    func delete(_ record: MenstrualRecord) async throws
}
