//
//  SettingMenuRow.swift
//  Mithm
//
//  Created by YunhakLee on 3/14/26.
//


import SwiftUI

struct SettingMenuRow: View {
    let item: SettingMenuItem
    @Binding var isOn: Bool
    var onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            Image(item.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 62, height: 62)
                .padding(11)

            Spacer().frame(width: 3)

            Text(item.title)
                .font(.pretendardSemiBold(18))
                .foregroundStyle(.textPrimary)

            Spacer()

            switch item.accessoryType {
            case .toggle:
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .padding(.trailing, 13)
                    .tint(.accent)
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primaryBlack)
                    .frame(width: 30, height: 30)
                    .padding(.trailing, 16)
            }
        }
        .frame(height: 84)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.gray50)
                .shadow(color: .buttonshadow, radius: 1, x: 0, y: 2)
        )
        .contentShape(RoundedRectangle(cornerRadius: 30))
        .onTapGesture {
            if item.accessoryType == .chevron {
                onTap?()
            }
        }
       
    }
}
