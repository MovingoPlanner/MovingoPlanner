//
//  TransportBadgeGalleryView.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-11-17.
//


import SwiftUI

struct TransportBadgeGalleryView: View {

    private struct GalleryItem: Identifiable {
        let id: String
        let title: String
        let leg: JourneyLeg
    }

    private let columns = [
        GridItem(.adaptive(minimum: 65), spacing: 18)
    ]

    // MARK: - UL buses 1–14

    private var ulBuses: [GalleryItem] {
        (1...14).map {
            makeItem(
                "UL Bus \($0)",
                operatorName: "UL",
                category: "Buss",
                number: "\($0)"
            )
        }
    }

    // MARK: - Ordinary buses

    private var buses: [GalleryItem] {
        [
            makeItem("SL Bus", operatorName: "SL", category: "Buss", number: "XX"),
            makeItem("UL Bus", operatorName: "UL", category: "Buss", number: "XX")
        ]
    }

    // MARK: - Trains

    private var trains: [GalleryItem] {
        [
            makeItem("SJ", operatorName: "SJ AB", category: "Tåg", number: "XX"),
            makeItem("Mälartåg", operatorName: "Mälardalstrafik", category: "Tåg", number: "XX"),
            makeItem("Pendeltåg", operatorName: "SL", category: "Pendeltåg", number: "XX")
        ]
    }

    // MARK: - Metro

    private var metro: [GalleryItem] {
        ["10", "11", "13", "14", "17", "18", "19"].map {
            makeItem(
                "Metro \($0)",
                operatorName: "SL",
                category: "Tunnelbana",
                number: $0
            )
        }
    }

    // MARK: - Commuter rail

    private var commuterRail: [GalleryItem] {
        ["40", "41", "42", "43", "44", "48"].map {
            makeItem(
                "Pendeltåg \($0)",
                operatorName: "SL",
                category: "Pendeltåg",
                number: $0
            )
        }
    }

    // MARK: - Tram / Light rail

    private var trams: [GalleryItem] {
        [
            ("7", "Spårvagn"),
            ("12", "Spårvagn"),
            ("21", "Lokalbana"),
            ("30", "Spårvagn"),
            ("31", "Spårvagn"),
            ("25", "Lokalbana"),
            ("26", "Lokalbana"),
            ("27", "Lokalbana"),
            ("28", "Lokalbana"),
            ("29", "Lokalbana")
        ].map { number, category in
            makeItem(
                "Tram \(number)",
                operatorName: "SL",
                category: category,
                number: number
            )
        }
    }

    // MARK: - Create test data

    private func makeItem(
        _ title: String,
        operatorName: String,
        category: String,
        number: String
    ) -> GalleryItem {
        makeItem(
            title,
            product: JourneyProduct(
                name: title,
                num: number,
                displayNumber: number,
                operatorName: operatorName,
                operatorCode: nil,
                categoryName: category,
                categoryCode: nil
            )
        )
    }

    private func makeItem(
        _ title: String,
        product: JourneyProduct? = nil
    ) -> GalleryItem {

        let origin = JourneyStop(
            name: "Stockholm C",
            extId: nil,
            date: "2026-11-17",
            time: "10:00"
        )

        let destination = JourneyStop(
            name: "Destination",
            extId: nil,
            date: "2026-11-17",
            time: "10:15"
        )

        let leg = JourneyLeg(
            type: nil,
            name: title,
            direction: nil,
            Origin: origin,
            Destination: destination,
            Product: product.map { [$0] },
            distanceMeters: nil
        )

        return GalleryItem(
            id: title,
            title: title,
            leg: leg
        )
    }

    // MARK: - Badge grid

    private func badgeGrid(_ items: [GalleryItem]) -> some View {
        LazyVGrid(columns: columns, spacing: 22) {
            ForEach(items) { item in
                VStack(spacing: 7) {
                    TransportBadge(leg: item.leg)

                    Text(item.title)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 55)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Transport symbols

    private var transportSymbols: some View {
        LazyVGrid(columns: columns, spacing: 22) {

            symbolTile("Metro", symbol: "T")
            symbolTile("Pendeltåg", systemImage: "tram.fill")
            symbolTile("Spårvagn", systemImage: "tram.fill")
            symbolTile("Tåg", systemImage: "lightrail.fill")
            symbolTile("Buss", systemImage: "bus.fill")
            symbolTile("Gång", systemImage: "figure.walk")
            symbolTile("Byte", systemImage: "arrow.left.arrow.right")
        }
        .padding(.vertical, 8)
    }

    private func symbolTile(
        _ title: String,
        systemImage: String? = nil,
        symbol: String? = nil
    ) -> some View {
        VStack(spacing: 7) {
            Group {
                if let symbol {
                    Text(symbol)
                        .font(.system(size: 23, weight: .bold))
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 23, weight: .medium))
                }
            }
            .foregroundStyle(.white)
            .frame(width: 42, height: 42)
            .background(Color(red: 0.25, green: 0.72, blue: 0.88))
            .clipShape(RoundedRectangle(cornerRadius: 5))

            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {

                section("UL STADSBUSSAR 1–14") {
                    badgeGrid(ulBuses)
                }

                section("BUSSAR") {
                    badgeGrid(buses)
                }

                section("TÅG") {
                    badgeGrid(trains)
                }

                section("TUNNELBANA") {
                    badgeGrid(metro)
                }

                section("PENDELTÅG") {
                    badgeGrid(commuterRail)
                }

                section("SPÅRVAGN / LOKALBANA") {
                    badgeGrid(trams)
                }

                section("TRANSPORTSYMBOLER") {
                    transportSymbols
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("Transport Gallery")
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)

            content()
        }
    }
}

#Preview {
    NavigationStack {
        TransportBadgeGalleryView()
    }
}
