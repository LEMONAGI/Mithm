//
//  SyncMenstrualCalendarUseCase.swift
//  Mithm
//
//  Created by YunhakLee on 3/15/26.
//

protocol SyncMenstrualCalendarUseCase {
    func execute(records: [MenstrualRecord], isEnabled: Bool) async throws
    func removeCalendar() async throws
}
