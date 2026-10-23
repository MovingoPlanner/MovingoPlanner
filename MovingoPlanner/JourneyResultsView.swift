//
//  JourneyResultsView.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-17.
//

import SwiftUI

struct JourneyResultsView: View {
    @ObservedObject var viewModel: JourneyPlannerViewModel
    @Binding var preferences: JourneyPreferences

    @EnvironmentObject private var savedJourneysStore: SavedJourneysStore

    private var sortedJourneys: [Journey] {
        switch preferences.sortOption {
        case .fastest:
            return viewModel.journeys.sorted {
                let firstDuration = $0.durationMinutes ?? Int.max
                let secondDuration = $1.durationMinutes ?? Int.max

                if firstDuration == secondDuration {
                    return $0.numberOfChanges < $1.numberOfChanges
                }

                return firstDuration < secondDuration
            }

        case .fewestChanges:
            return viewModel.journeys.sorted {
                if $0.numberOfChanges == $1.numberOfChanges {
                    return ($0.durationMinutes ?? Int.max)
                        < ($1.durationMinutes ?? Int.max)
                }

                return $0.numberOfChanges < $1.numberOfChanges
            }
        }
    }
    
    private var isCurrentJourneySaved: Bool {
        guard
            let origin = viewModel.selectedOrigin,
            let destination = viewModel.selectedDestination
        else {
            return false
        }

        return savedJourneysStore.journeys.contains { journey in
            journey.origin.stationID == origin.stationID &&
            journey.destination.stationID == destination.stationID
        }
    }

    private func toggleSavedJourney() {
        guard
            let origin = viewModel.selectedOrigin,
            let destination = viewModel.selectedDestination
        else {
            return
        }

        if let existingJourney = savedJourneysStore.journeys.first(where: {
            $0.origin.stationID == origin.stationID &&
            $0.destination.stationID == destination.stationID
        }) {
            savedJourneysStore.remove(id: existingJourney.id)
        } else {
            savedJourneysStore.add(
                origin: origin,
                destination: destination
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                JourneySearchPanel(
                    viewModel: viewModel,
                    preferences: $preferences
                )

                refreshButton

                if let error = viewModel.errorMessage {
                    Label(
                        error,
                        systemImage: "exclamationmark.circle"
                    )
                    .font(.footnote)
                    .foregroundStyle(.red)
                }

                resultsHeader

                sortingPicker

                if sortedJourneys.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(
                            Array(sortedJourneys.enumerated()),
                            id: \.element.id
                        ) { index, journey in
                            NavigationLink {
                                JourneyDetailView(journey: journey)
                            } label: {
                                journeyCard(
                                    journey,
                                    index: index
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Reseförslag")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleSavedJourney()
                } label: {
                    Image(
                        systemName: isCurrentJourneySaved
                            ? "star.fill"
                            : "star"
                    )
                    .foregroundStyle(
                        isCurrentJourneySaved ? .yellow : .primary
                    )
                }
                .disabled(
                    viewModel.selectedOrigin == nil ||
                    viewModel.selectedDestination == nil
                )
                .accessibilityLabel(
                    isCurrentJourneySaved
                        ? "Ta bort sparad resa"
                        : "Spara resa"
                )
            }
        }
    }

    // MARK: - Results Header

    private var resultsHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Reseförslag")
                .font(.title2.bold())

            Text("\(viewModel.journeys.count) resor hittades")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sorting

    private var sortingPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SORTERA EFTER")
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.secondary)

            Picker(
                "Sortera efter",
                selection: $preferences.sortOption
            ) {
                ForEach(JourneySortOption.allCases) { option in
                    Text(option.title)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Refresh Search

    private var refreshButton: some View {
        Button {
            Task {
                await viewModel.searchJourneys(
                    preferences: preferences
                )
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isLoadingJourneys {
                    ProgressView()
                        .tint(.blue)
                } else {
                    Image(systemName: "arrow.clockwise")
                }

                Text(
                    viewModel.isLoadingJourneys
                        ? "Söker efter resor..."
                        : "Uppdatera resvägar"
                )
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoadingJourneys)
    }

    // MARK: - Journey Card

    private func journeyCard(
        _ journey: Journey,
        index: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Departure, arrival and duration
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(journey.departureTime)

                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(journey.arrivalTime)
                    }
                    .font(.title3.bold())
                    .monospacedDigit()

                    Text(journey.durationText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                if index == 0 {
                    Text(
                        preferences.sortOption == .fastest
                            ? "SNABBAST"
                            : "MINST BYTEN"
                    )
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            Divider()

            // Visual itinerary
            journeyLegPreview(journey)

            Divider()

            // Origin and destination
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "circle.circle")
                    .foregroundStyle(.blue)

                Text(journey.originName)
                    .lineLimit(2)

                Spacer(minLength: 4)

                Image(systemName: "arrow.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)

                Spacer(minLength: 4)

                Text(journey.destinationName)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)

                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.blue)
            }
            .font(.subheadline.weight(.medium))

            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(.secondary)

                Text(
                    journey.numberOfChanges == 0
                        ? "Direktresa"
                        : journey.numberOfChanges == 1
                            ? "1 byte"
                            : "\(journey.numberOfChanges) byten"
                )

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)

                Text("Detaljer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(.primary.opacity(0.05))
        }
        .contentShape(RoundedRectangle(cornerRadius: 22))
    }
    
    // MARK: - Visual Itinerary

    private func journeyLegPreview(
        _ journey: Journey
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(
                    Array(journey.legs.enumerated()),
                    id: \.element.id
                ) { index, leg in

                    if index > 0 {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 4))
                            .foregroundStyle(.tertiary)
                    }

                    if leg.type == "WALK" {
                        Image(systemName: "figure.walk")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .frame(height: 30)
                            .accessibilityLabel("Gång")

                    } else if leg.type == "TRSF" {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                            .frame(height: 30)
                            .accessibilityLabel("Byte")

                    } else {
                        TransportBadge(leg: leg)
                            .fixedSize(
                                horizontal: true,
                                vertical: false
                            )
                    }
                }
            }
            .padding(.vertical, 3)
        }
    }
    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                "Inga resor att visa",
                systemImage: "tram"
            )
        } description: {
            Text(
                "Kontrollera dina hållplatser och tiden, och sök igen."
            )
        }
    }
}
