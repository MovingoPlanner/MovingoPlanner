//
//  DateTimePickerSheet.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-17.
//


import SwiftUI

struct DateTimePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var timeMode: JourneyTimeMode

    @Environment(\.dismiss) private var dismiss

    @State private var draftDate = Date.now

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(.secondary.opacity(0.6))
                .frame(width: 40, height: 5)
                .padding(.top, 4)

            Text("När vill du resa?")
                .font(.title3.weight(.bold))

            Picker("Tidstyp", selection: $timeMode) {
                ForEach(JourneyTimeMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .pickerStyle(.segmented)

            DatePicker(
                "Datum och tid",
                selection: $draftDate,
                in: Date.now...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "sv_SE"))
            .frame(maxWidth: .infinity)
            .clipped()

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button {
                    selectedDate = .now
                    dismiss()
                } label: {
                    Text("Åk nu")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    selectedDate = draftDate
                    dismiss()
                } label: {
                    Text("Klar")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .onAppear {
            draftDate = selectedDate
        }
        .presentationDetents([.height(490)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .presentationBackground(.ultraThinMaterial)
    }
}

#Preview {
    DateTimePickerSheet(
        selectedDate: .constant(.now),
        timeMode: .constant(.arrival)
    )
}
