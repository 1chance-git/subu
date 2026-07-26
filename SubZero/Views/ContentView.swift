////
//  ContentView.swift
//  SubZero
//
//  Root tab navigation for the app. Swiping left/right anywhere in the
//  content area switches tabs, in addition to tapping the tab bar.
//

import SwiftUI
import SwiftData

private enum AppTab: Int, CaseIterable {
    case dashboard, discover, cancel

    var next: AppTab {
        AppTab(rawValue: (rawValue + 1) % AppTab.allCases.count) ?? self
    }

    var previous: AppTab {
        AppTab(rawValue: (rawValue - 1 + AppTab.allCases.count) % AppTab.allCases.count) ?? self
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var storeManager = StoreManager()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #if os(iOS)
    @State private var showRemoveAds = false
    #endif

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house")
                    }
                    .tag(AppTab.dashboard)

                DiscoverSubscriptionsView()
                    .tabItem {
                        Label("Discover", systemImage: "sparkle.magnifyingglass")
                    }
                    .tag(AppTab.discover)

                CancelAssistantView()
                    .tabItem {
                        Label("Cancel", systemImage: "trash.circle")
                    }
                    .tag(AppTab.cancel)
            }
            .simultaneousGesture(tabSwipeGesture)

            #if os(iOS)
            if !storeManager.isAdsRemoved {
                adBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            #endif
        }
        #if os(iOS)
        .animation(
            reduceMotion ? .easeInOut(duration: 0.2) : .snappy,
            value: storeManager.isAdsRemoved
        )
        #endif
        .environment(storeManager)
        #if os(iOS)
        .task {
            AdManager.start()
            await AdManager.requestTrackingAuthorizationIfNeeded()
        }
        .sheet(isPresented: $showRemoveAds) {
            RemoveAdsView(storeManager: storeManager)
        }
        #endif
    }

    #if os(iOS)
    private var adBar: some View {
        VStack(spacing: 6) {
            BannerAdView()
                .frame(height: 50)

            Button("Remove Ads") {
                showRemoveAds = true
            }
            .font(.caption.weight(.semibold))
            .padding(.bottom, 6)
        }
        .background(.bar)
    }
    #endif

    /// Recognizes a clear horizontal swipe to move between tabs. Ignores
    /// swipes that start near the left edge so the system's interactive
    /// "swipe back" gesture inside a pushed detail screen still wins.
    private var tabSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 60, coordinateSpace: .local)
            .onEnded { value in
                guard value.startLocation.x > 24 else { return }

                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) * 1.5 else { return }

                if horizontal < 0 {
                    selectedTab = selectedTab.next
                } else {
                    selectedTab = selectedTab.previous
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.container)
}
