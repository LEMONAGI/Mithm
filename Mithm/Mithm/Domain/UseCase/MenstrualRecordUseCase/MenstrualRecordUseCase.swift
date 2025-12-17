//
//  MenstrualRecordUseCase.swift
//  Mithm
//
//  Created by YunhakLee on 12/17/25.
//

protocol MenstrualRecordUseCase {
    func fetchMenstrualRecords() async throws -> [MenstrualRecord]
    func saveMenstrualRecored(_ record: MenstrualRecord) async throws
}
