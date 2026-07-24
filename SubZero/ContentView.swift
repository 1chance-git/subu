////
//  ContentView.swift
//  SubZero
//
//  Root tab navigation for the app.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }

            AddSubscriptionView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }

            CancelAssistantView()
                .tabItem {
                    Label("Cancel", systemImage: "trash.circle.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.container)
}
