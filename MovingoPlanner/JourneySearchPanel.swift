//
//  JourneySearchPanel.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-17.
//


import SwiftUI

struct JourneySearchPanel: View {
    @ObservedObject var viewModel: JourneyPlannerViewModel
    @Binding var preferences: JourneyPreferences

    @State private var showingDateTimeSheet = false
    @State private var showingPreferencesSheet = false

    @FocusState private var focusedField: SearchField?

    private enum SearchField {
        case origin
        case destination
    }

    var body: some View {
        VStack(spacing: 20) {
            stationSearchCard
            searchControls
        }
    }

    // MARK: - Station Search Card

    private var stationSearchCard: some View {
        VStack(spacing: 0) {
            locationField(
                title: "FRÅN",
                text: $viewModel.originText,
                stops: viewModel.originStops,
                selection: .origin
            )
            .padding(.bottom, 18)

            Divider()
                .overlay(alignment: .trailing) {
                    Button {
                        viewModel.swapLocations()
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 42, height: 42)
                            .background(AppTheme.surface)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        AppTheme.accent.opacity(0.25),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .accessibilityLabel(
                        "Byt plats på avgång och destination"
                    )
                }

            locationField(
                title: "TILL",
                text: $viewModel.destinationText,
                stops: viewModel.destinationStops,
                selection: .destination
            )
            .padding(.top, 18)
        }
        .padding(20)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(AppTheme.separator, lineWidth: 1)
        }
    }

    // MARK: - Date, Time and Preferences

    private var searchControls: some View {
        HStack(spacing: 12) {
            Button {
                showingDateTimeSheet = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "clock")
                        .foregroundStyle(AppTheme.accent)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.timeMode.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(
                            viewModel.departureDate.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingDateTimeSheet) {
                DateTimePickerSheet(
                    selectedDate: $viewModel.departureDate,
                    timeMode: $viewModel.timeMode
                )
            }

            Spacer(minLength: 8)

            Button {
                showingPreferencesSheet = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundStyle(AppTheme.accent)
                    .padding(12)
                    .background(AppTheme.surface)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(AppTheme.separator, lineWidth: 1)
                    }
            }
            .accessibilityLabel("Resepreferenser")
            .sheet(isPresented: $showingPreferencesSheet) {
                JourneyPreferencesSheet(
                    preferences: preferences
                ) { updatedPreferences in
                    preferences = updatedPreferences
                }
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Location Field

    private func locationField(
        title: String,
        text: Binding<String>,
        stops: [TransitStop],
        selection: SearchField
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption2.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Image(
                    systemName: selection == .origin
                        ? "circle.circle"
                        : "mappin.circle.fill"
                )
                .foregroundStyle(AppTheme.accent)
                .font(.title3)

                TextField(
                    selection == .origin
                        ? "Välj start hållplats"
                        : "Välj destination",
                    text: text
                )
                .font(.body)
                .focused($focusedField, equals: selection)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .onChange(of: text.wrappedValue) { _, newValue in
                    if selection == .origin {
                        if viewModel.selectedOrigin?.name == newValue {
                            return
                        }

                        viewModel.selectedOrigin = nil
                    } else {
                        if viewModel.selectedDestination?.name == newValue {
                            return
                        }

                        viewModel.selectedDestination = nil
                    }

                    Task {
                        try? await Task.sleep(
                            nanoseconds: 300_000_000
                        )

                        guard text.wrappedValue == newValue else {
                            return
                        }

                        await viewModel.searchStops(
                            forOrigin: selection == .origin
                        )
                    }
                }
            }

            if !stops.isEmpty {
                VStack(spacing: 0) {
                    ForEach(stops.prefix(5)) { stop in
                        Button {
                            viewModel.selectStop(
                                stop,
                                forOrigin: selection == .origin
                            )

                            focusedField = nil
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "tram.fill")
                                    .foregroundStyle(AppTheme.accent)

                                VStack(
                                    alignment: .leading,
                                    spacing: 3
                                ) {
                                    Text(stop.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)

                                    Text("Kollektivtrafiks hållplats")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if stop.id != stops.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.leading, 32)
                .padding(.top, 8)
                .padding(.trailing, 4)
            }
        }
    }
}
