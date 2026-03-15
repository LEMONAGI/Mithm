//
//  MenstrualOverview.swift
//  Mithm
//
//  Created by YunhakLee on 3/15/26.
//


import Foundation

struct MenstrualOverview {
    let actualRecords: [MenstrualRecord]
    let allRecords: [MenstrualRecord]
    let prediction: MenstrualPredictionResult?
    
    init(
        actualRecords: [MenstrualRecord] = [],
        allRecords: [MenstrualRecord] = [],
        prediction: MenstrualPredictionResult? = nil
    ) {
        self.actualRecords = actualRecords
        self.allRecords = allRecords
        self.prediction = prediction
    }
}
