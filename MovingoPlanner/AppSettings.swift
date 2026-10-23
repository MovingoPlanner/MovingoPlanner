//
//  AppSettings.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-17.
//

import SwiftUI
import Combine

// MARK: - App language

enum AppLanguage: String, CaseIterable, Identifiable {
    case swedish = "sv"
    case english = "en"

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .swedish:
            return "Svenska"
        case .english:
            return "English"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

// MARK: - App settings

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var languageCode: String {
        didSet {
            UserDefaults.standard.set(
                languageCode,
                forKey: "appLanguage"
            )
        }
    }

    var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .swedish
    }

    private init() {
        languageCode = UserDefaults.standard.string(
            forKey: "appLanguage"
        ) ?? AppLanguage.swedish.rawValue
    }
}

// MARK: - Language settings

struct LanguageSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker(
                    "App språk",
                    selection: $settings.languageCode
                ) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title)
                            .tag(language.rawValue)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("Språk")
            } footer: {
                Text("Välj språket du vill använda för MovingoPlanner.")
            }
        }
        .navigationTitle("Språk")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
            .environmentObject(AppSettings.shared)
    }
}
