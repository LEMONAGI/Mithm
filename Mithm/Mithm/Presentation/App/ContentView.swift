//
//  ContentView.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: 0) {
                HomeView()
            } label: {
                Label("홈", systemImage: "house")
            }
            Tab(value: 1) {
                CalendarView()
            } label: {
                Label("달력", systemImage: "calendar")
            }
            Tab(value: 2) {
                SettingView()
            } label: {
                Label("설정", systemImage: "gearshape")
            }
        }
        .task {
            appState.loadUserSettings()
            do {
                try await appState.requestHealthKitAuthorization()
                try await appState.refreshMenstrualData()
            } catch {
                appState.menstrualRecordError = error
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task {
                    do {
                        try await appState.refreshMenstrualData()
                    } catch {
                        appState.menstrualRecordError = error
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDIContainer.makeAppState())
}
