//
//  SettingView.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI


struct SettingView: View {
    @State private var isHealthSyncOn: Bool = false
    @State private var isCalendarExportOn: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("설정")
                    .font(.pretendardBold(36))
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
        case .healthSync:
            SettingMenuRow(item: item, isOn: $isHealthSyncOn)
        case .calendarExport:
            SettingMenuRow(item: item, isOn: $isCalendarExportOn)
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
    SettingView()
}
