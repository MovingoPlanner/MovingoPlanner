//
//  JourneyDetailView.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-17.
//


import SwiftUI

struct JourneyDetailView: View {
    let journey: Journey
    
    @State private var platforms: [String: String] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                journeyHeader

                routeOverview

                VStack(alignment: .leading, spacing: 16) {
                    Text("Resans sträckor")
                        .font(.title2.bold())

                    ForEach(
                        Array(journey.legs.enumerated()),
                        id: \.element.id
                    ) { index, leg in
                        legCard(leg, index: index)
                    }
                }
            }
            .padding(20)
        }
        .task {
            print("🟢 JourneyDetailView platform task started")

            await loadPlatforms()

            print(
                "🔵 JourneyDetailView platform task finished. " +
                "Cancelled: \(Task.isCancelled)"
            )
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Resedetaljer")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Platform Lookup

    
    @MainActor
    private func loadPlatforms() async {
        for leg in journey.legs {
            guard leg.type == "JNY" else {
                continue
            }

            guard platforms[leg.id] == nil else {
                continue
            }

            let finalStop = journey.lastLeg?.Destination

            let directionStopID: String? = {
                guard
                    let direction = leg.direction,
                    let finalStop,
                    normalizeStopName(direction) == normalizeStopName(finalStop.name)
                else {
                    return nil
                }

                return finalStop.extId
            }()
            
            print("🧭 Direction: \(leg.direction ?? "nil")")
            print("🏁 Journey destination: \(journey.destinationName)")
            print("🆔 Final destination ID: \(journey.lastLeg?.Destination.extId ?? "nil")")

            if let platform = await TrafikverketService.shared.platform(
                for: leg,
                directionStopID: directionStopID
            ) {
                platforms[leg.id] = platform
            }
        }
    }

    private func directionStopID(for leg: JourneyLeg) -> String? {
        guard let direction = leg.direction else { return nil }

        let normalizedDirection = normalizeStopName(direction)

        // Match the train direction against stops in this journey.
        let stops = journey.legs.flatMap { leg in
            [leg.Origin, leg.Destination]
        }

        let matches = stops.filter { stop in
            let normalizedName = normalizeStopName(stop.name)

            return !normalizedName.isEmpty &&
                (normalizedDirection == normalizedName ||
                 normalizedDirection.hasPrefix(normalizedName))
        }

        // Prefer the longest matching station name to avoid partial matches.
        return matches.max {
            normalizeStopName($0.name).count <
            normalizeStopName($1.name).count
        }?.extId
    }

    private func normalizeStopName(_ name: String) -> String {
        let withoutParentheses = name.components(separatedBy: "(").first ?? name

        return withoutParentheses
            .replacingOccurrences(of: " station", with: "", options: .caseInsensitive)
            .folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: .current
            )
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }


    // MARK: - Journey Header

    private var journeyHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(journey.departureTime)
                Image(systemName: "arrow.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(journey.arrivalTime)
            }
            .font(.system(size: 30, weight: .bold))
            .monospacedDigit()

            Text(journey.durationText)
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right")

                Text(
                    journey.numberOfChanges == 0
                        ? "Direktresa"
                        : journey.numberOfChanges == 1
                            ? "1 byte"
                            : "\(journey.numberOfChanges) byten"
                )
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Route Overview

    private var routeOverview: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "circle.circle.fill")
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Från")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(journey.originName)
                        .font(.headline)
                }
            }

            HStack(spacing: 12) {
                Image(systemName: "arrow.down")
                    .foregroundStyle(.tertiary)

                Text("Resan tar \(journey.durationText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 3)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Till")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(journey.destinationName)
                        .font(.headline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Journey Leg

    private func legCard(
        _ leg: JourneyLeg,
        index: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                legIcon(for: leg)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(leg.transportName)
                        .font(.headline)

                    Text(legDescription(for: leg))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(leg.Origin.time ?? "--:--")

                    if let platform = platforms[leg.id] {
                        Text("Spår \(platform)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                    }

                    Text(leg.Destination.time ?? "--:--")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline.monospacedDigit())
            }

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                stopRow(
                    name: leg.Origin.name,
                    time: leg.Origin.time,
                    isOrigin: true
                )

                stopRow(
                    name: leg.Destination.name,
                    time: leg.Destination.time,
                    isOrigin: false
                )
            }
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(.primary.opacity(0.05))
        }
    }

    // MARK: - Leg Icon

    @ViewBuilder
    private func legIcon(for leg: JourneyLeg) -> some View {
        switch leg.type {
        case "WALK":
            Image(systemName: "figure.walk")
                .font(.title3)
                .foregroundStyle(.secondary)

        case "TRSF":
            Image(systemName: "arrow.left.arrow.right")
                .font(.title3)
                .foregroundStyle(.secondary)

        default:
            TransportBadge(leg: leg)
        }
    }

    // MARK: - Leg Description

    private func legDescription(for leg: JourneyLeg) -> String {
        switch leg.type {
        case "WALK":
            return "Gång"
        case "TRSF":
            return "Byte"
        default:
            return leg.direction.map { "Mot \($0)" }
                ?? "Kollektivtrafik"
        }
    }

    // MARK: - Stop Row

    private func stopRow(
        name: String,
        time: String?,
        isOrigin: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(
                systemName: isOrigin
                    ? "circle.fill"
                    : "circle"
            )
            .font(.caption)
            .foregroundStyle(isOrigin ? .blue : .secondary)
            .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(isOrigin ? "Avgång" : "Ankomst")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(name)
                    .font(.subheadline.weight(.medium))
            }

            Spacer(minLength: 8)

            Text(time ?? "--:--")
                .font(.subheadline.monospacedDigit().weight(.medium))
        }
    }
}
