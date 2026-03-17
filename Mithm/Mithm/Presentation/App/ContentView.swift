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
    @State private var showErrorAlert = false
    
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
        .onChange(of: appState.menstrualRecordError != nil) {
            if appState.menstrualRecordError != nil {
                showErrorAlert = true
            }
        }
        .alert(
            appState.menstrualRecordError?.alertTitle ?? "",
            isPresented: $showErrorAlert
        ) {
            Button("확인", role: .cancel) {
                appState.menstrualRecordError = nil
            }
        } message: {
            Text(appState.menstrualRecordError?.alertMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppDIContainer.makeAppState())
}
