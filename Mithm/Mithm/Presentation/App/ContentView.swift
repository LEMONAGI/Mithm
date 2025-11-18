//
//  ContentView.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
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
}

#Preview {
    ContentView()
}
