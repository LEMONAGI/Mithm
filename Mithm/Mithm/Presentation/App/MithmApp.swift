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
    @StateObject private var settingViewModel: SettingViewModel
    @StateObject private var cycleSettingViewModel: CycleSettingViewModel

    init() {
        let graph = AppDIContainer.makeAppDependencyGraph()

        _appState = StateObject(wrappedValue: graph.appState)
        _homeViewModel = StateObject(wrappedValue: graph.homeViewModel)
        _calendarViewModel = StateObject(wrappedValue: graph.calendarViewModel)
        _settingViewModel = StateObject(wrappedValue: graph.settingViewModel)
        _cycleSettingViewModel = StateObject(wrappedValue: graph.cycleSettingViewModel)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(homeViewModel)
                .environmentObject(calendarViewModel)
                .environmentObject(settingViewModel)
                .environmentObject(cycleSettingViewModel)
        }
    }
}
