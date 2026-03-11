//
//  WristTemperatureRecord.swift
//  Mithm
//
//  Created by Codex on 3/10/26.
//

import Foundation

struct WristTemperatureRecord: Identifiable, Hashable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let valueInCelsius: Double
}

