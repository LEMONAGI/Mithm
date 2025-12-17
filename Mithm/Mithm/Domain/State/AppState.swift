//
//  AppState.swift
//  Mithm
//
//  Created by YunhakLee on 12/17/25.
//

import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var menstrualRecord = MenstrualRecordState()
}

struct MenstrualRecordState {
    var loadState: LoadState<[MenstrualRecord]> = .notRequested
    
}

enum LoadState<T> {
    case notRequested
    case loading
    case loaded(T)
    case failed(Error)
}
