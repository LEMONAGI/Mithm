//
//  MithmApp.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI

@main
struct MithmApp: App {
    @StateObject private var appState = AppDIContainer.makeAppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
