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
                .padding(11)
                .frame(width: 84, height: 84)

            Spacer().frame(width: 3)

            Text(item.title)
                .font(.heading6)
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
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 2)
        )
        .contentShape(RoundedRectangle(cornerRadius: 30))
        .onTapGesture {
            if item.accessoryType == .chevron {
                onTap?()
            }
        }
       
    }
}
