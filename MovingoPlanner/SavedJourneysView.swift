//
//  SavedJourneysView.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-18.
//

import SwiftUI

struct SavedJourneysView: View {
    @EnvironmentObject private var savedJourneysStore: SavedJourneysStore
    @EnvironmentObject private var journeyNavigation: JourneyNavigationState
    @Environment(\.editMode) private var editMode

    @State private var journeyToDelete: SavedJourney?
    @State private var showingDeleteConfirmation = false
    @State private var isReordering = false

    var body: some View {
        NavigationStack {
            Group {
                if savedJourneysStore.journeys.isEmpty {
                    emptyState
                } else {
                    journeyList
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Sparat")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !savedJourneysStore.journeys.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isReordering ? "Klar" : "Ändra") {
                            withAnimation {
                                isReordering.toggle()
                                editMode?.wrappedValue = isReordering
                                    ? .active
                                    : .inactive
                            }
                        }
                        .fontWeight(.medium)
                    }
                }
            }
            .confirmationDialog(
                "Ta bort sparad resa?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Ta bort", role: .destructive) {
                    deleteJourney()
                }

                Button("Avbryt", role: .cancel) {
                    journeyToDelete = nil
                }
            } message: {
                Text("Resan tas bort från dina sparade resor.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label {
                Text("Inga sparade resor")
            } icon: {
                Image(systemName: "bookmark")
                    .symbolRenderingMode(.hierarchical)
            }
        } description: {
            Text(
                "Spara dina vanligaste resor från sökresultaten "
                + "så hittar du dem snabbt här."
            )
        }
    }

    // MARK: - Journey List

    private var journeyList: some View {
        List {
            Section {
                ForEach(savedJourneysStore.journeys) { journey in
                    Button {
                        openJourney(journey)
                    } label: {
                        journeyRow(journey)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(
                        EdgeInsets(
                            top: 8,
                            leading: 16,
                            bottom: 8,
                            trailing: 16
                        )
                    )
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            journeyToDelete = journey
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Ta bort", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            journeyToDelete = journey
                            showingDeleteConfirmation = true
                        } label: {
                            Label(
                                "Ta bort resa",
                                systemImage: "trash"
                            )
                        }
                    }
                    .moveDisabled(!isReordering)
                }
                .onMove(perform: savedJourneysStore.move)
            } header: {
                Text("DINA RESOR")
                    .tracking(1)
            } footer: {
                Text(
                    isReordering
                        ? "Dra resorna för att ändra ordningen."
                        : "Tryck på en resa för att söka igen. "
                            + "Svep åt vänster för att ta bort."
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Journey Row

    private func journeyRow(_ journey: SavedJourney) -> some View {
        HStack(spacing: 14) {
            routeIndicator

            VStack(alignment: .leading, spacing: 6) {
                Text(journey.origin.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(journey.destination.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: "arrow.up.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(
                    Color.blue.opacity(0.09),
                    in: Circle()
                )
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: - Route Indicator

    private var routeIndicator: some View {
        VStack(spacing: 3) {
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)

            Capsule()
                .fill(.blue.opacity(0.3))
                .frame(width: 2, height: 12)

            Circle()
                .strokeBorder(.blue, lineWidth: 1.5)
                .frame(width: 8, height: 8)
        }
        .frame(width: 24)
        .accessibilityHidden(true)
    }

    // MARK: - Open Journey

    private func openJourney(_ journey: SavedJourney) {
        journeyNavigation.pendingSavedJourney = journey
        journeyNavigation.selectedTab = .resa
    }

    // MARK: - Delete Journey

    private func deleteJourney() {
        guard let journey = journeyToDelete else {
            return
        }

        savedJourneysStore.remove(id: journey.id)
        journeyToDelete = nil
    }
}

#Preview {
    SavedJourneysView()
        .environmentObject(SavedJourneysStore())
        .environmentObject(JourneyNavigationState())
}
