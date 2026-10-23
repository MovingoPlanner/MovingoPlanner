//
//  JourneyPlannerViewModel.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-16.
//

import Foundation
import Combine

enum JourneyTimeMode: String, CaseIterable, Identifiable {
    case departure
    case arrival

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .departure:
            return "Avgång"

        case .arrival:
            return "Ankomst"
        }
    }
}

@MainActor
final class JourneyPlannerViewModel: ObservableObject {
    @Published var originText = ""
    @Published var destinationText = ""

    @Published var originStops: [TransitStop] = []
    @Published var destinationStops: [TransitStop] = []

    @Published var selectedOrigin: TransitStop?
    @Published var selectedDestination: TransitStop?

    @Published var isSearching = false
    @Published var errorMessage: String?

    @Published var journeys: [Journey] = []
    @Published var isLoadingJourneys = false

    @Published var departureDate = Date.now
    @Published var timeMode: JourneyTimeMode = .departure

    private let service = ResRobotService()

    // MARK: - Stop search

    func searchStops(forOrigin: Bool) async {
        let query = forOrigin ? originText : destinationText

        guard query.count >= 2 else {
            if forOrigin {
                originStops = []
            } else {
                destinationStops = []
            }

            return
        }

        isSearching = true
        errorMessage = nil

        defer {
            isSearching = false
        }

        do {
            let results = try await service.searchStops(query: query)

            print("Search query:", query)
            print("Stops decoded:", results.count)
            print("Stop names:", results.map(\.name))

            if forOrigin {
                originStops = results
            } else {
                destinationStops = results
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Swap locations

    func swapLocations() {
        let previousOrigin = originText
        originText = destinationText
        destinationText = previousOrigin

        let previousSelection = selectedOrigin
        selectedOrigin = selectedDestination
        selectedDestination = previousSelection

        originStops = []
        destinationStops = []
    }

    // MARK: - Select stop

    func selectStop(_ stop: TransitStop, forOrigin: Bool) {
        if forOrigin {
            selectedOrigin = stop
            originText = stop.name
            originStops = []
        } else {
            selectedDestination = stop
            destinationText = stop.name
            destinationStops = []
        }
    }

    // MARK: - Journey search

    /// Preferred search method: applies all supported journey preferences.
    func searchJourneys(preferences: JourneyPreferences) async {
        await performJourneySearch(
            maximumTransferTime: preferences.maximumTransferTime,
            preferences: preferences
        )
    }

    /// Compatibility method for existing calls that only specify
    /// a maximum transfer time.
    func searchJourneys(maximumTransferTime: Int? = nil) async {
        await performJourneySearch(
            maximumTransferTime: maximumTransferTime,
            preferences: nil
        )
    }

    private func performJourneySearch(
        maximumTransferTime: Int?,
        preferences: JourneyPreferences?
    ) async {
        guard let origin = selectedOrigin,
              let destination = selectedDestination else {
            errorMessage = "Please select both an origin and a destination."
            return
        }

        guard origin.stationID != destination.stationID else {
            errorMessage = "Please choose two different stops."
            return
        }

        isLoadingJourneys = true
        errorMessage = nil
        journeys = []

        defer {
            isLoadingJourneys = false
        }

        do {
            let fetchedJourneys = try await service.searchJourneys(
                from: origin,
                to: destination,
                departureDate: departureDate,
                timeMode: timeMode,
                maximumTransferTime: nil
            )

            guard let preferences else {
                journeys = fetchedJourneys

                if journeys.isEmpty {
                    errorMessage = "No journeys were found. Try another time."
                }

                return
            }

            journeys = fetchedJourneys.filter { journey in
                let fitsTransfer = journey.fitsMaximumTransferTime(
                    preferences.maximumTransferTime
                )

                let excludedOperator = journey.usesExcludedOperator(
                    preferences.excludedOperators
                )

                let fitsWalking = journey.fitsMaximumWalkingDistance(
                    preferences.maximumWalkingDistance
                )


                return fitsTransfer && !excludedOperator && fitsWalking
            }

            if journeys.isEmpty {
                if fetchedJourneys.isEmpty {
                    errorMessage = "No journeys were found. Try another time."
                } else {
                    errorMessage = """
                    No journeys match your preferences. Try changing your filters.
                    """
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
