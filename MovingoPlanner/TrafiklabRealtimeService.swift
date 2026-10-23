//
//  TrafiklabRealtimeService.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-18.
//


import Foundation

final class TrafiklabRealtimeService {

    static let shared = TrafiklabRealtimeService()

    private let baseURL =
        "https://realtime-api.trafiklab.se/v1/departures"

    private init() {}

    // MARK: - API Response Models

    private struct DepartureResponse: Decodable {
        let departures: [RealtimeDeparture]?
    }

    private struct RealtimeDeparture: Decodable {
        let scheduled: String?
        let route: RealtimeRoute?
        let scheduledPlatform: RealtimePlatform?
        let realtimePlatform: RealtimePlatform?
        let trip: RealtimeTrip?

        enum CodingKeys: String, CodingKey {
            case scheduled
            case route
            case scheduledPlatform = "scheduled_platform"
            case realtimePlatform = "realtime_platform"
            case trip
        }
    }

    private struct RealtimeRoute: Decodable {
        let designation: String?
        let name: String?
        let direction: String?
    }

    private struct RealtimePlatform: Decodable {
        let designation: String?
        let name: String?
    }
    
    private struct RealtimeTrip: Decodable {
        let tripID: String?
        let startDate: String?

        enum CodingKeys: String, CodingKey {
            case tripID = "trip_id"
            case startDate = "start_date"
        }
    }

    // MARK: - Trip Details Response Models

    private struct TripDetailsResponse: Decodable {
        let calls: [TripCall]?
    }

    private struct TripCall: Decodable {
        let scheduledDeparture: String?
        let realtimeDeparture: String?
        let stop: TripStop?
        let scheduledPlatform: TripPlatform?
        let realtimePlatform: TripPlatform?

        enum CodingKeys: String, CodingKey {
            case stop
            case scheduledDeparture
            case realtimeDeparture
            case scheduledPlatform = "scheduled_platform"
            case realtimePlatform = "realtime_platform"
        }
    }

    private struct TripStop: Decodable {
        let id: String?
        let areaID: String?
        let name: String?

        enum CodingKeys: String, CodingKey {
            case id
            case areaID = "area_id"
            case name
        }
    }

    private struct TripPlatform: Decodable {
        let id: String?
        let name: String?
    }

    // MARK: - Platform Lookup

    func platform(for leg: JourneyLeg) async -> String? {
        guard let areaID = leg.Origin.extId,
              !areaID.isEmpty else {
            print("❌ Trafiklab: Missing station ID")
            print("Station: \(leg.Origin.name)")
            return nil
        }

        guard let departureTime = departureDateTime(for: leg) else {
            print("❌ Trafiklab: Could not build departure date/time")
            print("Date: \(String(describing: leg.Origin.date))")
            print("Time: \(String(describing: leg.Origin.time))")
            return nil
        }

        guard let apiKey = APIKeyStore.shared.realtimeApiKey else {
            print("❌ Trafiklab: No API key found in Keychain")
            return nil
        }

        guard var components = URLComponents(
            string: baseURL
        ) else {
            print("❌ Trafiklab: Invalid base URL")
            return nil
        }

        components.path += "/\(areaID)/\(departureTime)"
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components.url else {
            print("❌ Trafiklab: Could not construct request URL")
            return nil
        }

        print("🚆 Trafiklab: Requesting platform")
        print("Station: \(leg.Origin.name)")
        print("Station ID: \(areaID)")
        print("Departure time: \(departureTime)")
        print("Train: \(leg.transportName)")
        print("Direction: \(leg.direction ?? "Unknown")")

    
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Trafiklab: Invalid HTTP response")
                return nil
            }

            print("Trafiklab HTTP status: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                // Print the error response, but never print the API key.
                let body = String(
                    data: data,
                    encoding: .utf8
                ) ?? "<Unreadable response>"

                print("❌ Trafiklab API error: \(body)")
                return nil
            }

            let result = try JSONDecoder().decode(
                DepartureResponse.self,
                from: data
            )

            let departures = result.departures ?? []

            print("Trafiklab departures received: \(departures.count)")

            // Show the candidates so we can investigate matching.
            for departure in departures {
                print("""
                ---
                Scheduled: \(departure.scheduled ?? "nil")
                Route: \(departure.route?.designation ?? "nil")
                Direction: \(departure.route?.direction ?? "nil")
                Scheduled platform: \
                \(departure.scheduledPlatform?.designation ?? "nil")
                Realtime platform: \
                \(departure.realtimePlatform?.designation ?? "nil")
                """)
            }

            let matchingDeparture = departures.first {
                matches($0, leg: leg)
            }

            guard let departure = matchingDeparture else {
                print("❌ Trafiklab: No departure matched this journey leg")
                return nil
            }
            
            print("==============")
            print("Matched train route: \(departure.route?.designation ?? "nil")")
            print("Matched direction: \(departure.route?.direction ?? "nil")")
            print("Trip ID: \(departure.trip?.tripID ?? "nil")")
            print("Trip start date: \(departure.trip?.startDate ?? "nil")")
            print("==============")

            let platform = departure.realtimePlatform?.designation
                ?? departure.scheduledPlatform?.designation
            
            print("🟡 CHECKPOINT 1: Departure matched")
            print("🟡 Platform: \(platform ?? "nil")")
            print("🟡 Trip ID: \(departure.trip?.tripID ?? "nil")")
            print("🟡 Start date: \(departure.trip?.startDate ?? "nil")")

            guard let platform, !platform.isEmpty else {
                print("⚠️ Trafiklab: No platform in departures response")
                
                print("🟠 CHECKPOINT 2: No platform — trying Trip Details")

                guard let tripID = departure.trip?.tripID,
                      let startDate = departure.trip?.startDate else {
                    print("⚠️ Trafiklab: Missing trip ID or start date")
                    return nil
                }

                return await platformFromTripDetails(
                    tripID: tripID,
                    startDate: startDate,
                    stationID: areaID,
                    departureTime: departureTime
                )
            }
            
            
            print("==============")
            print("Trip ID: \(departure.trip?.tripID ?? "nil")")
            print("Trip start date: \(departure.trip?.startDate ?? "nil")")
            print("==============")

            print("✅ Trafiklab: Matched platform \(platform)")

            return platform

        } catch {
            let nsError = error as NSError

            print("""
            ⚠️ Trafiklab request ended with an error.
            Error domain: \(nsError.domain)
            Error code: \(nsError.code)
            Error description: \(nsError.localizedDescription)
            Task cancelled: \(Task.isCancelled)
            """)

            return nil
        }
    }
    
    // MARK: - Trip Details Lookup

    private func platformFromTripDetails(
        tripID: String,
        startDate: String,
        stationID: String,
        departureTime: String
    ) async -> String? {
        
        print("🚨 TEST: platform(for:) WAS CALLED")
        
        print("🔴 CHECKPOINT 3: Entered Trip Details function")
        
        print("🔍 TRIP DETAILS FUNCTION ENTERED")
        print("🔍 Trip ID: \(tripID)")
        print("🔍 Start date: \(startDate)")
        print("🔍 Station ID: \(stationID)")
        print("🔍 Departure time: \(departureTime)")

        guard let apiKey = APIKeyStore.shared.realtimeApiKey else {
            print("❌ Trip Details: No API key found")
            return nil
        }

        let endpoint =
            "https://realtime-api.trafiklab.se/v1/trips"

        guard var components = URLComponents(
            string: "\(endpoint)/\(tripID)/\(startDate)"
        ) else {
            print("❌ Trip Details: Invalid URL")
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components.url else {
            print("❌ Trip Details: Could not construct URL")
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Trip Details: Invalid HTTP response")
                return nil
            }

            print("Trip Details HTTP status: \(httpResponse.statusCode)")
            
            if let json = try? JSONSerialization.jsonObject(with: data),
               let root = json as? [String: Any],
               let calls = root["calls"] as? [[String: Any]] {

                for call in calls {
                    let stop = call["stop"] as? [String: Any]
                    let stopName = stop?["name"] as? String

                    if stopName?.localizedCaseInsensitiveCompare("Vega")
                        == .orderedSame {

                        print("🔎 Raw Vega Trip Details response:")
                        print(call)
                    }
                }
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Trip Details: HTTP \(httpResponse.statusCode)")
                return nil
            }

            let result = try JSONDecoder().decode(
                TripDetailsResponse.self,
                from: data
            )

            let calls = result.calls ?? []

            print("Trip Details calls received: \(calls.count)")

            for call in calls {
                print("""
                ---
                Stop: \(call.stop?.name ?? "nil")
                Stop ID: \(call.stop?.id ?? "nil")
                Scheduled: \(call.scheduledDeparture ?? "nil")
                Scheduled platform: \
                \(call.scheduledPlatform?.id
                    ?? call.scheduledPlatform?.name
                    ?? "nil")
                Realtime platform: \
                \(call.realtimePlatform?.id
                    ?? call.realtimePlatform?.name
                    ?? "nil")                
                """)
            }

            let matchingCall = calls.first { call in
                call.stop?.areaID == stationID
            }

            guard let matchingCall else {
                print("⚠️ Trip Details: Could not match station area ID \(stationID)")
                return nil
            }

            print("✅ Matched stop: \(matchingCall.stop?.name ?? "Unknown")")
            print("Scheduled departure: \(matchingCall.scheduledDeparture ?? "nil")")
            print("Realtime departure: \(matchingCall.realtimeDeparture ?? "nil")")
            print("Scheduled platform: \(matchingCall.scheduledPlatform?.name ?? "nil")")
            print("Realtime platform: \(matchingCall.realtimePlatform?.name ?? "nil")")

            let platform = matchingCall.realtimePlatform?.name
                ?? matchingCall.scheduledPlatform?.name

            guard let platform, !platform.isEmpty else {
                print("⚠️ Trip Details: The API has no platform for this stop")
                return nil
            }

            print("✅ Trafiklab: Found platform \(platform)")
            return platform

        } catch {
            print(
                "❌ Trip Details request failed: " +
                "\(error.localizedDescription)"
            )
            return nil
        }
    }

    // MARK: - Matching

    private func matches(
        _ departure: RealtimeDeparture,
        leg: JourneyLeg
    ) -> Bool {
        guard let scheduled = departure.scheduled,
              let route = departure.route else {
            return false
        }

        // Match the departure to the journey's scheduled time.
        guard scheduled.hasPrefix(expectedDateTimePrefix(for: leg)) else {
            return false
        }

        // Match the route number when one is available.
        let product = leg.Product?.first

        let possibleNumbers = [
            product?.displayNumber,
            product?.num
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if !possibleNumbers.isEmpty {
            let routeNumber = route.designation ?? ""

            guard possibleNumbers.contains(routeNumber) else {
                return false
            }
        }

        // Use direction as an additional check when available.
        if let journeyDirection = leg.direction,
           let realtimeDirection = route.direction,
           !journeyDirection.isEmpty,
           !realtimeDirection.isEmpty {

            if !realtimeDirection.localizedCaseInsensitiveContains(
                journeyDirection
            ) &&
            !journeyDirection.localizedCaseInsensitiveContains(
                realtimeDirection
            ) {
                return false
            }
        }

        return true
    }

    // MARK: - Date Formatting

    private func departureDateTime(
        for leg: JourneyLeg
    ) -> String? {
        let date = leg.Origin.date
        let time = leg.Origin.time

        guard let date,
              let time,
              !date.isEmpty,
              !time.isEmpty else {
            return nil
        }

        let timeWithoutSeconds = String(time.prefix(5))

        guard timeWithoutSeconds.count == 5 else {
            return nil
        }

        return "\(date)T\(timeWithoutSeconds)"
    }

    private func expectedDateTimePrefix(
        for leg: JourneyLeg
    ) -> String {
        departureDateTime(for: leg) ?? ""
    }
}
