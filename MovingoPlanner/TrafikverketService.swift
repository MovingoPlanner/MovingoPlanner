//
//  TrafikverketService.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-23.
//


import Foundation

actor TrafikverketService {
    static let shared = TrafikverketService()

    private let apiURL = URL(
        string: "https://api.trafikinfo.trafikverket.se/v2/data.json"
    )!

    private let mappingURL = URL(
        string: "https://api.trafiklab.se/v2/samtrafiken/gtfs/extra/trafikverket_stops.txt"
    )!

    private var stationMapping: [String: [String]] = [:]

    private let includedFields = [
        "LocationSignature",
        "AdvertisedTrainIdent",
        "OperationalTrainNumber",
        "AdvertisedTimeAtLocation",
        "TrackAtLocation",
        "ActivityType",
        "ToLocation",
        "FromLocation",
        "Operator",
        "ProductInformation"
    ]

    private struct DepartureCandidate {
        let time: Date
        let track: String
        let train: String
        let destinationNames: [String]
    }

    enum ServiceError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case apiError(String)
        case mappingUnavailable

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Trafikverket-nyckeln saknas. Lägg till den i API-inställningarna."
            case .invalidResponse:
                return "Trafikverket returnerade ett ogiltigt svar."
            case .apiError(let message):
                return "Trafikverket: \(message)"
            case .mappingUnavailable:
                return "Kunde inte läsa Trafiklab:s stationsmappning."
            }
        }
    }

    // MARK: - Public API

    func testConnection() async throws -> String {
        let announcements = try await performQuery(makeQuery(limit: 1))

        return "Anslutningen fungerar! Trafikverket svarade med \(announcements.count) tågannonser."
    }

    /// Finds a platform using the origin, departure time and,
    /// when available, the selected train's direction.
    func platform(
        for leg: JourneyLeg,
        directionStopID: String? = nil
    ) async -> String? {
        guard
            leg.type == "JNY",
            let originID = leg.Origin.extId,
            let departureDate = leg.Origin.dateTime
        else {
            return nil
        }

        do {
            let originSignatures = try await signatures(for: originID)

            guard !originSignatures.isEmpty else {
                print("❌ No station mapping for origin: \(originID)")
                return nil
            }

            var directionSignatures: [String] = []

            if let directionStopID {
                directionSignatures = try await signatures(for: directionStopID)
            } else if let direction = leg.direction {
                directionSignatures = await signatures(
                    matchingDirection: direction
                )
            }

            print("🚉 Origin ID: \(originID)")
            print("🚉 Origin signatures: \(originSignatures)")
            print("🧭 Train direction: \(leg.direction ?? "unknown")")
            print("🎯 Direction stop ID: \(directionStopID ?? "nil")")
            print("🎯 Direction signatures: \(directionSignatures)")
            print("🕒 Scheduled departure: \(departureDate)")

            let lowerBound = departureDate.addingTimeInterval(-120)
            let upperBound = departureDate.addingTimeInterval(120)

            var candidates: [DepartureCandidate] = []

            for signature in originSignatures {
                let xml = makeDepartureQuery(
                    signature: signature,
                    from: lowerBound,
                    to: upperBound
                )

                let announcements = try await performQuery(xml)

                print(
                    "🚆 Signature \(signature): \(announcements.count) announcements"
                )

                for item in announcements {
                    printAnnouncement(item)
                }

                let matching = announcements.compactMap { item
                    -> DepartureCandidate? in

                    guard
                        string(item["LocationSignature"])?
                            .caseInsensitiveCompare(signature) == .orderedSame,
                        string(item["ActivityType"]) == "Avgang",
                        let timeString = string(
                            item["AdvertisedTimeAtLocation"]
                        ),
                        let time = parseDate(timeString),
                        abs(time.timeIntervalSince(departureDate)) <= 120,
                        let track = string(item["TrackAtLocation"]),
                        let train = string(
                            item["OperationalTrainNumber"]
                        ) ?? string(item["AdvertisedTrainIdent"])
                    else {
                        return nil
                    }

                    return DepartureCandidate(
                        time: time,
                        track: track,
                        train: train,
                        destinationNames: locationNames(item["ToLocation"])
                    )
                }

                candidates.append(contentsOf: matching)
            }

            guard !candidates.isEmpty else {
                print("⚠️ No matching departure with a published track.")
                return nil
            }

            // If we know the selected train's direction station,
            // require the advertised destination to match its signature.
            if !directionSignatures.isEmpty {
                let directionMatches = candidates.filter { candidate in
                    candidate.destinationNames.contains { destination in
                        directionSignatures.contains {
                            $0.caseInsensitiveCompare(destination) == .orderedSame
                        }
                    }
                }

                guard !directionMatches.isEmpty else {
                    print(
                        "⚠️ Departures found, but none matched the direction signatures."
                    )
                    return nil
                }

                candidates = directionMatches
            }

            // Never guess when remaining announcements point to
            // different platforms.
            let possibleTracks = Set(candidates.map(\.track))

            guard possibleTracks.count == 1 else {
                print(
                    "⚠️ Multiple possible platforms: \(possibleTracks.sorted())"
                )
                return nil
            }

            guard let best = candidates.min(by: {
                abs($0.time.timeIntervalSince(departureDate))
                    < abs($1.time.timeIntervalSince(departureDate))
            }) else {
                return nil
            }

            print("✅ Matched train: \(best.train)")
            print("✅ Selected platform: \(best.track)")

            return best.track

        } catch {
            print(
                "❌ Trafikverket platform lookup failed: \(error.localizedDescription)"
            )
            return nil
        }
    }
    
    
    func signatures(matchingDirection direction: String) async -> [String] {
        let stationName = direction
            .components(separatedBy: "(").first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? direction

        do {
            let stops = try await ResRobotService().searchStops(query: stationName)

            let target = normalizeStationName(stationName)

            // Prefer the exact station name, including "station" when present.
            let exactMatches = stops.filter {
                normalizeStationName($0.name) == target
            }

            // Try every exact match because ResRobot may return both
            // a parent station and a station-specific stop.
            for stop in exactMatches {
                print("🔎 Trying direction stop: \(stop.name) (\(stop.stationID))")

                let result = try await signatures(for: stop.stationID)

                if !result.isEmpty {
                    print("✅ Resolved \(stop.name) to Trafikverket signatures: \(result)")
                    return result
                }
            }

            print("❌ No Trafikverket signature found for: \(stationName)")
            print("🔎 Exact ResRobot matches: \(exactMatches.map { "\($0.name) (\($0.stationID))" })")
            return []
        } catch {
            print("❌ Direction lookup failed: \(error.localizedDescription)")
            return []
        }
    }


    private func normalizeStationName(_ name: String) -> String {
        let withoutParentheses = name.components(separatedBy: "(").first ?? name

        return withoutParentheses
            .replacingOccurrences(
                of: " station",
                with: "",
                options: .caseInsensitive
            )
            .folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: .current
            )
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }


    // MARK: - Station Mapping

    private func signatures(for stopID: String) async throws -> [String] {
        if stationMapping.isEmpty {
            try await loadStationMapping()
        }

        return stationMapping[stopID] ?? []
    }

    private func loadStationMapping() async throws {
        var request = URLRequest(url: mappingURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard
            let http = response as? HTTPURLResponse,
            (200..<300).contains(http.statusCode),
            let contents = String(data: data, encoding: .utf8)
        else {
            throw ServiceError.mappingUnavailable
        }

        var mapping: [String: [String]] = [:]

        for rawLine in contents.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !line.isEmpty else {
                continue
            }

            let columns = line.split(
                separator: ",",
                omittingEmptySubsequences: false
            )

            guard columns.count == 2 else {
                continue
            }

            let stopID = columns[0]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\u{FEFF}", with: "")

            let signature = columns[1]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard
                !stopID.isEmpty,
                !signature.isEmpty,
                stopID.lowercased() != "stop_id",
                signature.allSatisfy(\.isLetter)
            else {
                continue
            }

            if !mapping[stopID, default: []].contains(signature) {
                mapping[stopID, default: []].append(signature)
            }
        }

        guard !mapping.isEmpty else {
            throw ServiceError.mappingUnavailable
        }

        stationMapping = mapping

        print("✅ Loaded \(mapping.count) Trafikverket station mappings.")
    }

    // MARK: - Trafikverket Requests

    private func performQuery(
        _ xml: String
    ) async throws -> [[String: Any]] {
        guard
            let key = await APIKeyStore.shared.trafikverketApiKey,
            !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw ServiceError.missingAPIKey
        }

        let body = xml.replacingOccurrences(
            of: "{{API_KEY}}",
            with: xmlEscaped(key)
        )

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 20

        request.setValue(
            "text/xml; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        request.httpBody = Data(body.utf8)

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            throw ServiceError.apiError("HTTP \(http.statusCode).")
        }

        guard
            let root = try JSONSerialization.jsonObject(with: data)
                as? [String: Any],
            let responseObject = root["RESPONSE"] as? [String: Any]
        else {
            throw ServiceError.invalidResponse
        }

        if let results = responseObject["RESULT"] as? [[String: Any]] {
            return results.flatMap { result in
                result["TrainAnnouncement"] as? [[String: Any]] ?? []
            }
        }

        if responseObject["RESULT"] == nil {
            return []
        }

        throw ServiceError.invalidResponse
    }

    // MARK: - Query Builders

    private func makeQuery(limit: Int) -> String {
        let includes = includedFields.map {
            "<INCLUDE>\($0)</INCLUDE>"
        }.joined(separator: "\n")

        return """
        <REQUEST>
          <LOGIN authenticationkey="{{API_KEY}}" />
          <QUERY objecttype="TrainAnnouncement" schemaversion="1.8" limit="\(limit)">
            \(includes)
          </QUERY>
        </REQUEST>
        """
    }

    private func makeDepartureQuery(
        signature: String,
        from start: Date,
        to end: Date
    ) -> String {
        let startString = iso8601(start)
        let endString = iso8601(end)

        let includes = includedFields.map {
            "<INCLUDE>\($0)</INCLUDE>"
        }.joined(separator: "\n")

        return """
        <REQUEST>
          <LOGIN authenticationkey="{{API_KEY}}" />
          <QUERY objecttype="TrainAnnouncement" schemaversion="1.8" limit="100">
            <FILTER>
              <AND>
                <EQ name="LocationSignature" value="\(xmlEscaped(signature))" />
                <EQ name="ActivityType" value="Avgang" />
                <GT name="AdvertisedTimeAtLocation" value="\(startString)" />
                <LT name="AdvertisedTimeAtLocation" value="\(endString)" />
              </AND>
            </FILTER>
            \(includes)
          </QUERY>
        </REQUEST>
        """
    }

    // MARK: - Helpers

    private func string(_ value: Any?) -> String? {
        guard let value, !(value is NSNull) else {
            return nil
        }

        let result = String(describing: value)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return result.isEmpty ? nil : result
    }

    private func locationNames(_ value: Any?) -> [String] {
        guard let locations = value as? [[String: Any]] else {
            return []
        }

        return locations.compactMap {
            string($0["LocationName"])?.uppercased()
        }
    }

    private func parseDate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        if let date = fractional.date(from: value) {
            return date
        }

        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]

        return standard.date(from: value)
    }

    private func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        return formatter.string(from: date)
    }

    private func xmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private func printAnnouncement(_ item: [String: Any]) {
        print("""
        ── TRAFIKVERKET ANNOUNCEMENT ──
        Station: \(string(item["LocationSignature"]) ?? "nil")
        Activity: \(string(item["ActivityType"]) ?? "nil")
        Time: \(string(item["AdvertisedTimeAtLocation"]) ?? "nil")
        Track: \(string(item["TrackAtLocation"]) ?? "nil")
        Train: \(string(item["OperationalTrainNumber"]) ?? string(item["AdvertisedTrainIdent"]) ?? "nil")
        From: \(locationNames(item["FromLocation"]))
        To: \(locationNames(item["ToLocation"]))
        Operator: \(string(item["Operator"]) ?? "nil")
        ───────────────────────────────
        """)
    }
}
