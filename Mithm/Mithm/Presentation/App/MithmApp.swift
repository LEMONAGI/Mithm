//
//  MithmApp.swift
//  Mithm
//
//  Created by YunhakLee on 11/18/25.
//

import SwiftUI
import SwiftData

@main
struct MithmApp: App {
//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([
//            Item.self,
//        ])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()

//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//        //.modelContainer(sharedModelContainer)
//    }
    
    @Environment(\.openURL) private var openURL
        
        var body: some Scene {
            WindowGroup {
                CalendarDebugView()
                    .onOpenURL { url in
                        DeepLinkHandler.shared.handle(url)
                    }
            }
        }
}
