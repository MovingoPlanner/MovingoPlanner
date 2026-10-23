//
//  SavedJourney.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-18.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Saved Journey

struct SavedJourney: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    let origin: TransitStop
    let destination: TransitStop

    init(
        id: UUID = UUID(),
        name: String? = nil,
        origin: TransitStop,
        destination: TransitStop
    ) {
        self.id = id
        self.name = name ?? "\(origin.name) → \(destination.name)"
        self.origin = origin
        self.destination = destination
    }
}

// MARK: - Saved Journeys Store

@MainActor
final class SavedJourneysStore: ObservableObject {

    @Published private(set) var journeys: [SavedJourney] = []

    private let storageKey = "savedJourneys"

    init() {
        loadJourneys()
    }

    // MARK: Save

    @discardableResult
    func add(
        origin: TransitStop,
        destination: TransitStop
    ) -> Bool {

        // Prevent saving the same route more than once.
        let alreadyExists = journeys.contains { journey in
            journey.origin.stationID == origin.stationID &&
            journey.destination.stationID == destination.stationID
        }

        guard !alreadyExists else {
            return false
        }

        let journey = SavedJourney(
            origin: origin,
            destination: destination
        )

        journeys.append(journey)
        persistJourneys()

        return true
    }

    // MARK: Delete

    func remove(id: UUID) {
        journeys.removeAll { $0.id == id }
        persistJourneys()
    }

    // MARK: Reorder

    func move(from source: IndexSet, to destination: Int) {
        journeys.move(fromOffsets: source, toOffset: destination)
        persistJourneys()
    }

    // MARK: Persistence

    private func loadJourneys() {
        guard let data = UserDefaults.standard.data(
            forKey: storageKey
        ) else {
            return
        }

        do {
            journeys = try JSONDecoder().decode(
                [SavedJourney].self,
                from: data
            )
        } catch {
            print(
                "Could not load saved journeys:",
                error.localizedDescription
            )
        }
    }

    private func persistJourneys() {
        do {
            let data = try JSONEncoder().encode(journeys)

            UserDefaults.standard.set(
                data,
                forKey: storageKey
            )
        } catch {
            print(
                "Could not save journeys:",
                error.localizedDescription
            )
        }
    }
}
