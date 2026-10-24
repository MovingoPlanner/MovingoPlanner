//
//  MovingoPlannerApp.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-16.
//

import SwiftUI

@main
struct MovingoPlannerApp: App {
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(settings)
                .environment(\.locale, settings.language.locale)
                .tint(AppTheme.accent)
        }
    }
}
