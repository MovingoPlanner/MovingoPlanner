//
//  MainTabView.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-16.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var settings: AppSettings
    
    @StateObject private var savedJourneysStore = SavedJourneysStore()
    @StateObject private var journeyNavigation = JourneyNavigationState()
    
    private var selectedTab: Binding<MainTab> {
        $journeyNavigation.selectedTab
    }

    var body: some View {
        TabView(selection: selectedTab) {
            // MARK: - Resa

            ContentView()
                .tag(MainTab.resa)
                .tabItem {
                    Label("Resa", systemImage: "magnifyingglass")
                }

            // MARK: - Karta

            NavigationStack {
                PlaceholderTabView(
                    title: "Karta",
                    subtitle: "Utforska din resa på kartan.",
                    symbol: "map"
                )
            }
            .tag(MainTab.karta)
            .tabItem {
                Label("Karta", systemImage: "map")
            }

            // MARK: - Sparat

            SavedJourneysView()
                .tag(MainTab.sparat)
                .tabItem {
                    Label("Sparat", systemImage: "bookmark")
                }

            // MARK: - Mer

            NavigationStack {
                SettingsHomeView()
            }
            .tag(MainTab.mer)
            .tabItem {
                Label("Mer", systemImage: "ellipsis")
            }
        }
        .tint(AppTheme.accent)
        .background(AppTheme.background)
        .environment(\.locale, settings.language.locale)
        .environmentObject(savedJourneysStore)
        .environmentObject(journeyNavigation)
    }
}

// MARK: - Settings home

private struct SettingsHomeView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            // MARK: API Settings
            Section {
                NavigationLink {
                    APISettingsView()
                } label: {
                    Label(
                        "API-inställningar",
                        systemImage: "key.horizontal"
                    )
                }
            } header: {
                Text("Anslutningar")
            } footer: {
                Text(
                    "Hantera API-nycklar och anslutningar för appens tjänster."
                )
            }

            // MARK: Language

            Section {
                NavigationLink {
                    LanguageSettingsView()
                } label: {
                    HStack {
                        Label(
                            "Språk",
                            systemImage: "globe"
                        )

                        Spacer()

                        Text(settings.language.title)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("App inställningar")
            }

            // MARK: About

            Section {
                HStack {
                    Label(
                        "Version",
                        systemImage: "tram.fill"
                    )

                    Spacer()

                    Text("\(getAppVersion()) (\(getBuildNumber()))")
                        .foregroundStyle(.secondary)
                }

                Link(
                    "ResRobot information",
                    destination: URL(
                        string: "https://www.trafiklab.se/api/our-apis/resrobot-v21/"
                    )!
                )
            } header: {
                Text("Om")
            }
        }
        .navigationTitle("Mer")
        .navigationBarTitleDisplayMode(.large)
    }
    
    func getAppVersion() -> String {
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return appVersion
        }
        return "Unknown"
    }

    func getBuildNumber() -> String {
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return buildNumber
        }
        return "Unknown"
    }

}

// MARK: - Placeholder tabs

private struct PlaceholderTabView: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(AppTheme.accent)

            Text(title)
                .font(.largeTitle.bold())

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppSettings.shared)
}
