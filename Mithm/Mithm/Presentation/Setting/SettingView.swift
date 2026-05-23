//
//  SettingView.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI


struct SettingView: View {
    @EnvironmentObject private var settingViewModel: SettingViewModel
    @Environment(\.openURL) private var openURL
    @State private var showPredictionMethodSetting = false
    @State private var showCycleSetting = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("설정")
                        .font(.pretendardBold(36))
                        .foregroundStyle(.textPrimary)
                        .padding(.bottom, 26)
                    ForEach(SettingMenuItem.allCases, id: \.self) { item in
                        settingMenuRow(for: item)
                    }
                }
                .padding(.top, 26)
                .padding(.horizontal, 20)
            }
            .navigationDestination(isPresented: $showPredictionMethodSetting) {
                PredictionMethodSettingView()
                    .environmentObject(settingViewModel)
            }
            .navigationDestination(isPresented: $showCycleSetting) {
                CycleSettingView()
            }
        }
    }
}
extension SettingView {
    
    @ViewBuilder
    private func settingMenuRow(for item: SettingMenuItem) -> some View {
        switch item {
        case .calendarExport:
            SettingMenuRow(item: item, isOn: Binding(
                get: { settingViewModel.calendarExportEnabled },
                set: { settingViewModel.setCalendarExportEnabled($0) }
            ))
        case .predictionMethod:
            SettingMenuRow(item: item, isOn: .constant(false)) {
                showPredictionMethodSetting = true
            }
        case .cycleSetting:
            SettingMenuRow(item: item, isOn: .constant(false)) {
                showCycleSetting = true
            }
        case .privacyPolicy:
            SettingMenuRow(item: item, isOn: .constant(false)) {
                if let url = item.url { openURL(url) }
            }
        case .support:
            SettingMenuRow(item: item, isOn: .constant(false)) {
                if let url = item.url { openURL(url) }
            }
        }
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    SettingView()
        .environmentObject(graph.settingViewModel)
}
