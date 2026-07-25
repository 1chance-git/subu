//
//  SubZeroApp.swift
//  SubZero
//
//  App entry point. Configures the SwiftData ModelContainer used across
//  the entire app and hosts the root ContentView.
//

import SwiftUI
import SwiftData

@main
struct SubuApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Subscription.self,
            SubscriptionStatusEvent.self,
        ])
        let persistentConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        if let persistentContainer = try? ModelContainer(for: schema, configurations: [persistentConfiguration]) {
            return persistentContainer
        }

        // If the on-disk store cannot be opened (for example, a corrupted
        // database file after an interrupted write), fall back to an
        // in-memory store so Subu remains fully usable for the current
        // session instead of failing to launch.
        let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [inMemoryConfiguration])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
