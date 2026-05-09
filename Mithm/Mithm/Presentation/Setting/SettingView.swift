//
//  SettingView.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI


struct SettingView: View {
    @EnvironmentObject private var settingViewModel: SettingViewModel
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("설정")
                    .font(.pretendardBold(36))
                    .foregroundStyle(.textPrimary)
                    .padding(.bottom, 26)
                ForEach(SettingMenuItem.allCases, id: \.self) { item in
                    settingMenuRow(for: item)
                }
                Spacer()
            }
            .padding(.top, 26)
            .padding(.horizontal, 20)
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
                // TODO: Navigate to prediction method setting
            }
        case .cycleSetting:
            SettingMenuRow(item: item, isOn: .constant(false)) {
                // TODO: Navigate to cycle setting
            }
        case .privacyPolicy:
            SettingMenuRow(item: item, isOn: .constant(false)) {
                // TODO: Navigate to privacy policy
            }
        case .support:
            SettingMenuRow(item: item, isOn: .constant(false)) {
                // TODO: Navigate to support
            }
        }
    }
}

#Preview {
    let graph = AppDIContainer.makeAppDependencyGraph()
    SettingView()
        .environmentObject(graph.settingViewModel)
}
