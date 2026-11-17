//
//  AppSettingsView.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-11-17.
//


import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {

                // MARK: - Connections

                settingsSection(title: "Anslutningar") {
                    settingsLink(
                        title: "API-inställningar",
                        subtitle: "Hantera appens API-anslutningar",
                        symbol: "key.horizontal"
                    ) {
                        APISettingsView()
                    }

                    settingsDivider

                    settingsLink(
                        title: "Galleri av symboler",
                        subtitle: "Se linjer och transportsymboler",
                        symbol: "square.grid.2x2"
                    ) {
                        TransportBadgeGalleryView()
                    }
                }

                // MARK: - App settings

                settingsSection(title: "Appinställningar") {
                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        HStack(spacing: 14) {
                            settingsIcon("globe")

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Språk")
                                    .foregroundStyle(AppTheme.primaryText)

                                Text("Välj appens språk")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()

                            Text(settings.language.title)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - About

                settingsSection(title: "Om") {
                    HStack(spacing: 14) {
                        settingsIcon("info.circle")

                        Text("Version")
                            .foregroundStyle(AppTheme.primaryText)

                        Spacer()

                        Text("\(getAppVersion()) (\(getBuildNumber()))")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    settingsDivider

                    Link(
                        destination: URL(
                            string: "https://www.trafiklab.se/api/our-apis/resrobot-v21/"
                        )!
                    ) {
                        HStack(spacing: 14) {
                            settingsIcon("globe")

                            Text("ResRobot information")
                                .foregroundStyle(AppTheme.primaryText)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Mer")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Section

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppTheme.separator, lineWidth: 1)
            }
        }
    }

    // MARK: - Settings link

    private func settingsLink<Destination: View>(
        title: String,
        subtitle: String,
        symbol: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                settingsIcon(symbol)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .foregroundStyle(AppTheme.primaryText)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }

    // MARK: - Components

    private func settingsIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(AppTheme.accent)
            .frame(width: 38, height: 38)
            .background(AppTheme.accent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 11))
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(AppTheme.separator)
            .frame(height: 1)
            .padding(.leading, 54)
    }

    // MARK: - Version information

    private func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "Unknown"
    }

    private func getBuildNumber() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            ?? "Unknown"
    }
}

#Preview {
    NavigationStack {
        AppSettingsView()
            .environmentObject(AppSettings.shared)
    }
}
