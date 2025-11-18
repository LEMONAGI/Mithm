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
            HomeView()
            
            CalendarView()
            
            SettingView()
        }
    }
}

#Preview {
    ContentView()
}
