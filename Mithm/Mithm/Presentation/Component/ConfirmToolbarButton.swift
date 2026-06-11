//
//  ConfirmToolbarButton.swift
//  Mithm
//

import SwiftUI

/// 툴바 confirmationAction 자리에 놓는 확인(저장) 버튼.
/// iOS 26 미만에서는 confirm 역할 버튼을 쓸 수 없어 텍스트 버튼으로 대체한다.
struct ConfirmToolbarButton: View {

    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(role: .confirm, action: action)
        } else {
            Button(action: action) {
                Text("저장")
                    .font(.pretendardSemiBold(17))
            }
        }
    }
}
