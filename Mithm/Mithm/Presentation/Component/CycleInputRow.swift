//
//  CycleInputRow.swift
//  Mithm
//

import SwiftUI

struct CycleInputRow: View {

    let label: String
    let value: Int
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.pretendardRegular(17))
                .foregroundStyle(.textPrimary)
            Spacer()
            Text("\(value)")
                .font(.pretendardRegular(17))
                .foregroundStyle(isExpanded ? Color.accentColor : Color(.textPrimary))
                .frame(width: 50)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .background(Color(UIColor.secondarySystemFill))
                .cornerRadius(30)
            Text("일")
                .font(.pretendardRegular(17))
                .foregroundStyle(.textPrimary)
        }
        .frame(height: 52)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
