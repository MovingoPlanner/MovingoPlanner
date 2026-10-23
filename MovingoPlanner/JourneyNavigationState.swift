//
//  JourneyNavigationState.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-18.
//

import SwiftUI
import Combine

enum MainTab: Hashable {
    case resa
    case karta
    case sparat
    case mer
}

@MainActor
final class JourneyNavigationState: ObservableObject {
    @Published var selectedTab: MainTab = .resa
    @Published var pendingSavedJourney: SavedJourney?
}
