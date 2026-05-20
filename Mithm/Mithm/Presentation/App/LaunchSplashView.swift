//
//  LaunchSplashView.swift
//  Mithm
//
//  Created by Codex on 5/13/26.
//

import SwiftUI

struct LaunchSplashView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    Image("LaunchImage")
                        .resizable()
                        .scaledToFit()
                        .clipped()
                        .ignoresSafeArea()
                }
                .ignoresSafeArea()

                Text("launch_splash.app_name")
                    .font(.pretendardExtraBold(80))
                    .foregroundStyle(.primaryBlack)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 0.215
                    )

                Text("launch_splash.headline")
                    .font(.pretendardThin(18))
                    .foregroundStyle(.primaryBlack)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.82)
                    .frame(width: geometry.size.width * 0.82)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 0.375
                    )

                Text("launch_splash.notice")
                    .font(.pretendardSemiBold(10))
                    .foregroundStyle(.primaryBlack.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.74)
                    .frame(width: geometry.size.width * 0.84)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * 0.915
                    )
            }
        }
        .ignoresSafeArea()
    }
        

    private func logoFontSize(for size: CGSize) -> CGFloat {
        min(size.width * 0.245, 92)
    }

    private func headlineFontSize(for size: CGSize) -> CGFloat {
        min(size.width * 0.073, 28)
    }

    private func noticeFontSize(for size: CGSize) -> CGFloat {
        min(size.width * 0.033, 13)
    }
}

#Preview {
    LaunchSplashView()
}
