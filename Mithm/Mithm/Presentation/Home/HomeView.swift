//
//  HomeView.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI

struct HomeView: View {
    @State var currentType: PhaseType = .luteal
    var body: some View {
        ZStack(alignment: .topTrailing) {
            currentType.color
                .ignoresSafeArea()
            Image(currentType.image)
                .resizable()
                .scaledToFit()
                .frame(width: 402, height: 402/373*470)
                .offset(y: 30)
                
            VStack(alignment: .leading, spacing: 0) {
                Text("다음 월경")
                    .bold()
                Spacer().frame(height: 6)
                Text("12월 18일 · D-23")
                    .bold()
                    .font(.title2)
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Text(currentType.name)
                    .font(.system(size: 100, weight: .black, design: .monospaced))
                Text(currentType.description)
                    .bold()
                Spacer()
                Button {
                    currentType = currentType.nextType
                } label: {
                    RoundedRectangle(cornerRadius: 30)
                        .foregroundStyle(Color.black)
                        .frame(height: 120)
                        .overlay {
                            Text("월경 시작")
                                .foregroundStyle(.white)
                                .bold()
                                .font(.title)
                        }
                }
                
                Spacer()
            }
           .padding()
        }
    }
}

#Preview {
    HomeView()
}
