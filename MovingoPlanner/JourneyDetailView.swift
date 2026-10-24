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
            VStack(alignment: .leading, spacing: 28) {
                journeyHeader

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("Resans sträckor")
                            .font(.title2.bold())

                        Spacer()

                        Text(
                            journey.numberOfChanges == 0
                                ? "Direktresa"
                                : "\(journey.numberOfChanges) byten"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    }

                    ForEach(
                        Array(journey.legs.enumerated()),
                        id: \.element.id
                    ) { index, leg in
                        legCard(leg, index: index)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .task {
            print("🟢 JourneyDetailView platform task started")
            await loadPlatforms()
            print(
                "🔵 JourneyDetailView platform task finished. " +
                "Cancelled: \(Task.isCancelled)"
            )
        }
        .background(AppTheme.background)
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
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("AVGÅNG")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)

                    Text(formattedTime(journey.departureTime))
                        .font(.system(size: 34, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 4)

                Image(systemName: "arrow.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(.quaternary, in: Circle())

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 5) {
                    Text("ANKOMST")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)

                    Text(formattedTime(journey.arrivalTime))
                        .font(.system(size: 34, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }

            Divider()

            HStack(spacing: 0) {
                summaryItem(
                    icon: "clock",
                    title: journey.durationText,
                    subtitle: "Restid"
                )

                Spacer(minLength: 8)

                summaryItem(
                    icon: "arrow.left.arrow.right",
                    title: journey.numberOfChanges == 0
                        ? "Direkt"
                        : "\(journey.numberOfChanges)",
                    subtitle: journey.numberOfChanges == 1
                        ? "Byte"
                        : "Byten"
                )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(journey.originName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Capsule()
                        .fill(AppTheme.accent.gradient)
                        .frame(width: 3, height: 22)

                    Text(journey.destinationName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.surface,
            in: RoundedRectangle(cornerRadius: 26)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .strokeBorder(AppTheme.separator, lineWidth: 1)
        }
    }

    private func summaryItem(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 38, height: 38)
                .background(
                    AppTheme.accent.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 12)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }


    // MARK: - Route Overview

    private var routeOverview: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "circle.circle.fill")
                    .foregroundStyle(AppTheme.accent)

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
                    .foregroundStyle(AppTheme.accent)

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
        let isWalking = leg.type == "WALK"
        let isTransfer = leg.type == "TRSF"

        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    
                    Circle()
                        .fill(isWalking || isTransfer
                              ? Color.secondary.opacity(0.12)
                              : AppTheme.accent.opacity(0.12))
                        .frame(width: 44, height: 44)

                    legIcon(for: leg)
                    
                }

                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 2)
                    .frame(minHeight: 34)
                    .padding(.top, 8)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(leg.transportName)
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)

                        if !isWalking && !isTransfer {
                            TransportBadge(leg: leg)
                                .fixedSize()
                        }
                    }

                    Text(legDescription(for: leg))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !isWalking && !isTransfer {
                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AVGÅNG")
                                .font(.caption2.weight(.bold))
                                .tracking(0.8)
                                .foregroundStyle(.secondary)

                            Text(formattedTime(leg.Origin.time ?? "--:--"))
                                .font(.system(size: 25, weight: .bold))
                                .monospacedDigit()
                        }

                        Spacer(minLength: 4)

                        if let platform = platforms[leg.id] {
                            VStack(spacing: 3) {
                                Text("SPÅR")
                                    .font(.caption2.weight(.bold))
                                    .tracking(0.8)

                                Text(platform)
                                    .font(.system(size: 25, weight: .bold))
                                    .monospacedDigit()
                            }
                            .foregroundStyle(AppTheme.accent)
                            .frame(minWidth: 70)
                            .padding(.vertical, 9)
                            .padding(.horizontal, 12)
                            .background(
                                AppTheme.accent.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(AppTheme.accent.opacity(0.25), lineWidth: 1)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Spår \(platform)")
                        }
                    }

                    Divider()

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
                } else {
                    VStack(alignment: .leading, spacing: 12) {
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                AppTheme.surface,
                in: RoundedRectangle(cornerRadius: 22)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            }
        }
    }


    // MARK: - Leg Icon
    
    @ViewBuilder
    private func legIcon(for leg: JourneyLeg) -> some View {
        switch leg.type {
        case "WALK":
            Image(systemName: "figure.walk")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

        case "TRSF":
            Image(systemName: "arrow.left.arrow.right")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)

        default:
            TransportModeIcon(leg: leg)
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
    
    // MARK: - Time Helper
    
    private func formattedTime(_ time: String) -> String {
        String(time.prefix(5))
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
            .foregroundStyle(isOrigin ? AppTheme.accent : AppTheme.secondaryText)
            .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(isOrigin ? "Avgång" : "Ankomst")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(name)
                    .font(.subheadline.weight(.medium))
            }

            Spacer(minLength: 8)

            Text(formattedTime(time ?? "--:--"))
                .font(.subheadline.monospacedDigit().weight(.medium))
        }
    }
}
