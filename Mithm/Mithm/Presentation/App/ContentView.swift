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
    @State private var isShowingLaunchSplash = true
    @State private var showErrorAlert = false
    @State private var showAutoCloseAlert = false
    
    var body: some View {
        ZStack {
            mainContent

            if isShowingLaunchSplash {
                LaunchSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            await appState.performInitialLoad()
        }
        .task {
            await hideLaunchSplash()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task {
                    await appState.refreshOnForeground()
                }
            }
        }
        .onChange(of: appState.didAutoCloseMenstruation) {
            if appState.didAutoCloseMenstruation {
                showAutoCloseAlert = true
            }
        }
        .alert(
            String(localized: "이전 월경 종료를 자동으로 기록했습니다!"),
            isPresented: $showAutoCloseAlert
        ) {
            Button("확인", role: .cancel) {
                appState.didAutoCloseMenstruation = false
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

    private var mainContent: some View {
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
    }

    private func hideLaunchSplash() async {
        do {
            try await Task.sleep(nanoseconds: 1500_000_000)
        } catch {
            return
        }

        await MainActor.run {
            withAnimation(.easeOut(duration: 0.18)) {
                isShowingLaunchSplash = false
            }
        }
    }
}

#Preview {
    let appState = AppDIContainer.makeAppState()
    ContentView()
        .environmentObject(appState)
        .environmentObject(AppDIContainer.makeHomeViewModel(appState: appState))
        .environmentObject(AppDIContainer.makeCalendarViewModel(appState: appState))
        .environmentObject(SettingViewModel(appState: appState))
        .environmentObject(CycleSettingViewModel(appState: appState))
}
