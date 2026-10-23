//
//  JourneyPreferencesSheet.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-17.
//


import SwiftUI

struct JourneyPreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draftPreferences: JourneyPreferences

    let onSave: (JourneyPreferences) -> Void

    private let operators = [
        "SJ",
        "Mälartåg",
        "SL",
        "UL"
    ]

    init(
        preferences: JourneyPreferences,
        onSave: @escaping (JourneyPreferences) -> Void
    ) {
        _draftPreferences = State(initialValue: preferences)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Maximal bytestid")

                            Spacer()

                            Text("\(draftPreferences.maximumTransferTime) min")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        Slider(
                            value: Binding(
                                get: {
                                    Double(draftPreferences.maximumTransferTime)
                                },
                                set: {
                                    draftPreferences.maximumTransferTime =
                                        Int($0.rounded())
                                }
                            ),
                            in: 5...60,
                            step: 5
                        )

                        Text(
                            "Begränsa hur länge du vill vänta mellan två avgångar."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Byten")
                }

                Section {
                    ForEach(operators, id: \.self) { operatorName in
                        Toggle(
                            operatorName,
                            isOn: Binding(
                                get: {
                                    draftPreferences.excludedOperators
                                        .contains(operatorName)
                                },
                                set: { isExcluded in
                                    if isExcluded {
                                        draftPreferences.excludedOperators
                                            .insert(operatorName)
                                    } else {
                                        draftPreferences.excludedOperators
                                            .remove(operatorName)
                                    }
                                }
                            )
                        )
                    }
                } header: {
                    Text("Undvik operatörer")
                } footer: {
                    Text("Aktivera ett reglage för att undvika operatören.")
                        .font(.footnote)
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Maximal gångsträcka")

                            Spacer()

                            Text("\(draftPreferences.maximumWalkingDistance) m")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        Slider(
                            value: Binding(
                                get: {
                                    Double(
                                        draftPreferences.maximumWalkingDistance
                                    )
                                },
                                set: {
                                    draftPreferences.maximumWalkingDistance =
                                        Int($0.rounded())
                                }
                            ),
                            in: 100...2000,
                            step: 100
                        )
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Gångavstånd")
                } footer: {
                    Text(
                        "Avser gångavstånd under resan. Faktisk filtrering kräver att avstånden kan hämtas från reseinformationen."
                    )
                }

                Section {
                    Toggle(
                        "Sök även närliggande stationer",
                        isOn: $draftPreferences.includeNearbyStations
                    )
                    .disabled(true)
                } header: {
                    Text("Sökning")
                } footer: {
                    Text(
                        "När funktionen är aktiverad kan sökningen även omfatta alternativa stationer i närheten."
                    )
                }
            }
            .navigationTitle("Resepreferenser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Avbryt")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSave(draftPreferences)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Spara inställningar")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }
}
