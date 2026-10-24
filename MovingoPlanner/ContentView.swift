//
//  ContentView.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-16.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = JourneyPlannerViewModel()
    
    @EnvironmentObject private var journeyNavigation: JourneyNavigationState
    @EnvironmentObject private var savedJourneysStore: SavedJourneysStore
    
    @State private var showingResults = false
    
    @State private var journeyPreferences = JourneyPreferences()
    
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""

    @FocusState private var focusedField: SearchField?

    private enum SearchField {
        case origin
        case destination
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    header

                    JourneySearchPanel(
                        viewModel: viewModel,
                        preferences: $journeyPreferences
                    )

                    searchButton

                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    savedJourneysSection

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingResults) {
                JourneyResultsView(
                    viewModel: viewModel,
                    preferences: $journeyPreferences
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Text("Trafikläget")
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                        Image(systemName: "exclamationmark.triangle")
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(10)
                }
            }
            .onChange(of: journeyNavigation.pendingSavedJourney) { _, journey in
                guard let journey else { return }

                viewModel.selectStop(journey.origin, forOrigin: true)
                viewModel.selectStop(journey.destination, forOrigin: false)
                
                journeyNavigation.pendingSavedJourney = nil
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MOVINGO")
                .font(.caption.weight(.bold))
                .tracking(3)
                .foregroundStyle(AppTheme.accent)

            Text("Vart ska vi?")
                .font(.system(size: 38, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)

            Text("Din resa i Mälardalsregionen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }
    
    private var searchButton: some View {
        Button {
            focusedField = nil

            Task {
                await viewModel.searchJourneys(
                    preferences: journeyPreferences
                )

                if !viewModel.journeys.isEmpty {
                    showingResults = true
                }
            }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isLoadingJourneys {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "magnifyingglass")
                }

                Text(
                    viewModel.isLoadingJourneys
                        ? "Söker efter resväg..."
                        : "Sök resväg"
                )
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .foregroundStyle(.white)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(
            viewModel.selectedOrigin == nil ||
            viewModel.selectedDestination == nil ||
            viewModel.isLoadingJourneys
        )
        .opacity(
            viewModel.selectedOrigin == nil ||
            viewModel.selectedDestination == nil ? 0.6 : 1
        )
    }

    // MARK: - Saved Journeys

    @ViewBuilder
    private var savedJourneysSection: some View {
        if !savedJourneysStore.journeys.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("SPARADE RESOR")
                        .font(.caption.weight(.bold))
                        .tracking(1.3)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if savedJourneysStore.journeys.count > 5 {
                        Button {
                            journeyNavigation.selectedTab = .sparat
                        } label: {
                            HStack(spacing: 4) {
                                Text("Visa alla")
                                Image(systemName: "chevron.right")
                            }
                            .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(AppTheme.accent)
                    }
                }

                VStack(spacing: 0) {
                    ForEach(
                        Array(savedJourneysStore.journeys.prefix(5))
                    ) { journey in
                        savedJourneyRow(journey)

                        if journey.id != savedJourneysStore.journeys
                            .prefix(5).last?.id {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(AppTheme.separator, lineWidth: 1)
                }
            }
        }
    }

    // MARK: - Saved Journey Row

    private func savedJourneyRow(_ journey: SavedJourney) -> some View {
        Button {
            openSavedJourney(journey)
        } label: {
            HStack(spacing: 12) {
                // Route indicator
                VStack(spacing: 3) {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 7, height: 7)

                    Rectangle()
                        .fill(AppTheme.accent.opacity(0.3))
                        .frame(width: 2, height: 9)

                    Circle()
                        .strokeBorder(AppTheme.accent, lineWidth: 1.5)
                        .frame(width: 7, height: 7)
                }
                .frame(width: 12)

                // Station names
                VStack(alignment: .leading, spacing: 5) {
                    Text(journey.origin.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(journey.destination.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(journey.origin.name) till \(journey.destination.name)"
        )
    }

    // MARK: - Open Saved Journey

    private func openSavedJourney(_ journey: SavedJourney) {
        journeyNavigation.pendingSavedJourney = journey
        journeyNavigation.selectedTab = .resa
    }
    
    
}

#Preview {
    ContentView()
        .environmentObject(SavedJourneysStore())
        .environmentObject(JourneyNavigationState())
}
