//
//  ResRobotService.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-16.
//

import Foundation

enum ResRobotError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "ResRobot API key is missing."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .requestFailed(let message):
            return message
        }
    }
}

struct StopLookupResponse: Decodable {
    let stopLocationOrCoordLocation: [StopLocationOrCoordLocation]?

    var stops: [TransitStop] {
        stopLocationOrCoordLocation?.compactMap {
            $0.stopLocation
        } ?? []
    }

    struct StopLocationOrCoordLocation: Decodable {
        let stopLocation: TransitStop?

        enum CodingKeys: String, CodingKey {
            case stopLocation = "StopLocation"
        }
    }
}

struct ResRobotService {
    private let baseURL = "https://api.resrobot.se/v2.1"

    private var apiKey: String {
        APIKeyStore.shared.apiKey
            ?? ProcessInfo.processInfo.environment["RESROBOT_API_KEY"]
            ?? ""
    }

    func searchStops(query: String) async throws -> [TransitStop] {
        
        //print(ProcessInfo.processInfo.environment["RESROBOT_API_KEY"])
        
        let searchText = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !searchText.isEmpty else {
            return []
        }

        guard !apiKey.isEmpty else {
            throw ResRobotError.missingAPIKey
        }

        var components = URLComponents(
            string: "\(baseURL)/location.name"
        )!

        components.queryItems = [
            URLQueryItem(name: "input", value: searchText),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "accessId", value: apiKey)
        ]

        guard let url = components.url else {
            throw ResRobotError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        print("========== RAW RESROBOT RESPONSE ==========")
        print(String(data: data, encoding: .utf8) ?? "Unable to read response")
        print("========== END RAW RESPONSE ==========")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResRobotError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ResRobotError.requestFailed(
                "ResRobot returned HTTP \(httpResponse.statusCode)."
            )
        }
        

        do {
            let result = try JSONDecoder().decode(
                StopLookupResponse.self,
                from: data
            )

            return result.stops
        } catch {
            throw ResRobotError.requestFailed(
                "Couldn't read the station results: \(error.localizedDescription)"
            )
        }
    }
    
    func searchJourneys(
        from origin: TransitStop,
        to destination: TransitStop,
        departureDate: Date = .now,
        timeMode: JourneyTimeMode = .departure,
        maximumTransferTime: Int? = nil
    ) async throws -> [Journey] {

        guard !apiKey.isEmpty else {
            throw ResRobotError.missingAPIKey
        }

        var components = URLComponents(
            string: "\(baseURL)/trip"
        )!

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = TimeZone.current
        timeFormatter.dateFormat = "HH:mm"

        components.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "accessId", value: apiKey),
            URLQueryItem(name: "originId", value: origin.stationID),
            URLQueryItem(name: "destId", value: destination.stationID),
            URLQueryItem(
                name: "date",
                value: dateFormatter.string(from: departureDate)
            ),
            URLQueryItem(
                name: "time",
                value: timeFormatter.string(from: departureDate)
            ),
            URLQueryItem(name: "searchForArrival",
                         value: timeMode == .arrival ? "1" : "0"),
            URLQueryItem(name: "numF", value: "3"),
            URLQueryItem(name: "changeTimePercent", value: "35"),
            URLQueryItem(
                name: "maxChangeTime",
                value: maximumTransferTime.map { String($0) }
            ),
            URLQueryItem(name: "passlist", value: "1"),
            URLQueryItem(name: "lang", value: "sv")
            
        ]

        guard let url = components.url else {
            throw ResRobotError.invalidResponse
        }
        
        print("========== RESROBOT REQUEST ==========")
        print("Origin: \(origin.name) (\(origin.stationID))")
        print("Destination: \(destination.name) (\(destination.stationID))")
        print("Date: \(dateFormatter.string(from: departureDate))")
        print("Time: \(timeFormatter.string(from: departureDate))")
        print("Time mode: \(timeMode)")
        print("Search for arrival: \(timeMode == .arrival ? 1 : 0)")
        print("Maximum transfer time: \(maximumTransferTime.map(String.init) ?? "nil")")
        print("URL: \(components.scheme ?? "")://\(components.host ?? "")\(components.path)")
        print("Query parameters:")

        for item in components.queryItems ?? [] {
            if item.name == "accessId" {
                print("  accessId: [hidden]")
            } else {
                print("  \(item.name): \(item.value ?? "nil")")
            }
        }

        print("========== END REQUEST ==========")

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        print("========== RAW RESROBOT RESPONSE ==========")
        print(String(data: data, encoding: .utf8) ?? "Unable to read response")
        print("========== END RAW RESPONSE ==========")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResRobotError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ResRobotError.requestFailed(
                "Journey search failed with HTTP \(httpResponse.statusCode)."
            )
        }

        do {
            let result = try JSONDecoder().decode(JourneyResponse.self, from: data)

            print("========== RESROBOT JOURNEYS ==========")

            for (index, journey) in result.journeys.enumerated() {
                print("""
                JOURNEY \(index + 1)
                Departure: \(journey.departureTime)
                Arrival: \(journey.arrivalTime)
                Duration: \(journey.durationText)
                Changes: \(journey.numberOfChanges)
                Transfer waits: \(String(describing: journey.transferWaitMinutes))
                """)

                for leg in journey.legs {
                    print("""
                      Type: \(leg.type ?? "nil")
                      From: \(leg.Origin.name) \(leg.Origin.time ?? "--:--")
                      To: \(leg.Destination.name) \(leg.Destination.time ?? "--:--")
                      Transport: \(leg.transportName)
                    """)
                }
            }

            print("========== END JOURNEYS ==========")

            return result.journeys
        } catch {
            print("Journey decoding error:", error)
            print(String(data: data, encoding: .utf8) ?? "No response body")

            throw ResRobotError.requestFailed(
                "Couldn't decode the journey results: \(error.localizedDescription)"
            )
        }
    }
}
