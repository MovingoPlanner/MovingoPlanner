//
//  JourneyPreferences.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-17.
//

import Foundation

enum JourneySortOption: String, CaseIterable, Identifiable {
    case fastest
    case fewestChanges

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fastest:
            return "Snabbast resa"
        case .fewestChanges:
            return "Färre byten"
        }
    }
}

struct JourneyPreferences: Equatable {
    var maximumTransferTime = 30
    var excludedOperators: Set<String> = []
    var maximumWalkingDistance = 1000
    var includeNearbyStations = false
    var sortOption: JourneySortOption = .fastest
}
