//
//  MithmApp.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI

@main
struct MithmApp: App {
    @StateObject private var appState: AppState
    @StateObject private var homeViewModel: HomeViewModel

    init() {
        let appState = AppDIContainer.makeAppState()

        _appState = StateObject(wrappedValue: appState)
        _homeViewModel = StateObject(wrappedValue: AppDIContainer.makeHomeViewModel(appState: appState))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(homeViewModel)
        }
    }
}
