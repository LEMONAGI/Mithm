//
//  MenstrualRecordInteractor.swift
//  Mithm
//
//  Created by YunhakLee on 12/17/25.
//

import Foundation

struct MenstrualRecordInteractor {
    let appState = AppState()
    
    
    func fetchMenstrualRecords() async throws {
        appState.menstrualRecord.loadState = .loaded(<#T##[MenstrualRecord]#>)
    }
}

