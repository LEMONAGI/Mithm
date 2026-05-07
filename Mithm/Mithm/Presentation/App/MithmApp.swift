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
    @StateObject private var calendarViewModel: CalendarViewModel

    init() {
        let graph = AppDIContainer.makeAppDependencyGraph()

        _appState = StateObject(wrappedValue: graph.appState)
        _homeViewModel = StateObject(wrappedValue: graph.homeViewModel)
        _calendarViewModel = StateObject(wrappedValue: graph.calendarViewModel)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(homeViewModel)
                .environmentObject(calendarViewModel)
        }
    }
}
