//
//  TransitStop.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-16.
//

import Foundation

struct TransitStop: Identifiable, Codable, Hashable {
    let id: String
    let extId: String?
    let name: String
    let lon: String?
    let lat: String?

    enum CodingKeys: String, CodingKey {
        case id
        case extId
        case name
        case lon
        case lat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        id = try container.decode(String.self, forKey: .id)
        extId = try container.decodeIfPresent(
            String.self,
            forKey: .extId
        )
        name = try container.decode(String.self, forKey: .name)

        lon = Self.decodeCoordinate(
            from: container,
            forKey: .lon
        )

        lat = Self.decodeCoordinate(
            from: container,
            forKey: .lat
        )
    }

    private static func decodeCoordinate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> String? {
        if let value = try? container.decodeIfPresent(
            String.self,
            forKey: key
        ) {
            return value
        }

        if let value = try? container.decode(
            Double.self,
            forKey: key
        ) {
            return String(value)
        }

        return nil
    }

    var displayName: String {
        name
    }

    var stationID: String {
        extId ?? id
    }
}
