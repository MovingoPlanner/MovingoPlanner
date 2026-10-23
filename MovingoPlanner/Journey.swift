//
//  Journey.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-16.
//

import Foundation

struct JourneyResponse: Decodable {
    let Trip: [Journey]?

    var journeys: [Journey] {
        Trip ?? []
    }
}

struct Journey: Decodable, Identifiable {
    let idx: Int?
    let duration: String?
    let LegList: JourneyLegList

    var id: String {
        idx.map(String.init) ?? "\(departureTime)-\(arrivalTime)"
    }

    var legs: [JourneyLeg] {
        LegList.Leg
    }

    var firstLeg: JourneyLeg? {
        legs.first
    }

    var lastLeg: JourneyLeg? {
        legs.last
    }

    var departureTime: String {
        firstLeg?.Origin.time ?? "--:--"
    }

    var arrivalTime: String {
        lastLeg?.Destination.time ?? "--:--"
    }

    var originName: String {
        firstLeg?.Origin.name ?? "Unknown origin"
    }

    var destinationName: String {
        lastLeg?.Destination.name ?? "Unknown destination"
    }

    var numberOfChanges: Int {
        max(0, legs.filter { $0.type == "JNY" }.count - 1)
    }

    // MARK: - Duration

    var durationMinutes: Int? {
        guard let duration else {
            return nil
        }

        let value = duration.replacingOccurrences(
            of: "PT",
            with: ""
        )

        var totalMinutes = 0
        var number = ""

        for character in value {
            if character.isNumber {
                number.append(character)
            } else {
                guard let amount = Int(number) else {
                    continue
                }

                switch character {
                case "H":
                    totalMinutes += amount * 60

                case "M":
                    totalMinutes += amount

                default:
                    break
                }

                number = ""
            }
        }

        return totalMinutes > 0 ? totalMinutes : nil
    }

    var durationText: String {
        guard let minutes = durationMinutes else {
            return "Restid saknas"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 && remainingMinutes > 0 {
            return "\(hours) h \(remainingMinutes) min"
        } else if hours > 0 {
            return "\(hours) h"
        } else {
            return "\(remainingMinutes) min"
        }
    }

    // MARK: - Transfer time filtering

    /// The time between arrival and departure for each connection
    /// between consecutive public-transport legs.
    ///
    /// Returns nil if the necessary dates or times are missing.
    var transferWaitMinutes: [Int]? {
        let publicTransportLegs = legs.filter {
            $0.type == "JNY"
        }

        guard publicTransportLegs.count > 1 else {
            return []
        }

        var waits: [Int] = []

        for index in 0..<(publicTransportLegs.count - 1) {
            let arrivingLeg = publicTransportLegs[index]
            let departingLeg = publicTransportLegs[index + 1]

            guard
                let arrival = arrivingLeg.Destination.dateTime,
                let departure = departingLeg.Origin.dateTime
            else {
                return nil
            }

            let seconds = departure.timeIntervalSince(arrival)
            let minutes = Int((seconds / 60).rounded(.down))

            // A negative transfer wait usually means the timestamps
            // are incomplete or inconsistent, so treat it as unknown.
            guard minutes >= 0 else {
                return nil
            }

            waits.append(minutes)
        }

        return waits
    }

    func fitsMaximumTransferTime(_ maximumMinutes: Int) -> Bool {
        guard let waits = transferWaitMinutes else {
            // Keep the journey if the API didn't provide enough data.
            return true
        }

        return waits.allSatisfy { $0 <= maximumMinutes }
    }

    // MARK: - Walking distance filtering

    /// Total walking distance in metres.
    ///
    /// Returns nil if a walking leg doesn't include a distance.
    var totalWalkingDistanceMeters: Double? {
        let walkingLegs = legs.filter {
            $0.type == "WALK"
        }

        guard !walkingLegs.isEmpty else {
            print("Walking distance: no walking legs")
            return 0
        }

        var totalDistance = 0.0

        for leg in walkingLegs {

            guard let distance = leg.distanceMeters else {
                print("Walking distance unavailable for this leg.")
                return nil
            }

            totalDistance += distance
        }


        return totalDistance
    }

    func fitsMaximumWalkingDistance(_ maximumMeters: Int) -> Bool {
        guard let distance = totalWalkingDistanceMeters else {
            // Don't reject a journey if the distance is unavailable.
            return true
        }

        return distance <= Double(maximumMeters)
    }

    // MARK: - Operator filtering

    func usesExcludedOperator(_ excludedOperators: Set<String>) -> Bool {
        legs
            .filter { $0.type == "JNY" }
            .flatMap { $0.Product ?? [] }
            .contains { product in
                excludedOperators.contains { excludedOperator in
                    product.matchesOperator(excludedOperator)
                }
            }
    }
}

struct JourneyLegList: Decodable {
    let Leg: [JourneyLeg]
}

struct JourneyLeg: Decodable, Identifiable {
    let type: String?
    let name: String?
    let direction: String?
    let Origin: JourneyStop
    let Destination: JourneyStop
    let Product: [JourneyProduct]?

    // ResRobot may provide the leg distance in metres as "dist".
    let distanceMeters: Double?

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case direction
        case Origin
        case Destination
        case Product
        case distanceMeters = "dist"
    }

    var id: String {
        "\(Origin.name)-\(Destination.name)-\(String(describing: Origin.time))"
    }

    var transportName: String {
        Product?.first?.displayName ?? name ?? legTypeName
    }

    var legTypeName: String {
        switch type {
        case "WALK":
            return "Walk"

        case "TRSF":
            return "Transfer"

        default:
            return "Public transport"
        }
    }
}

struct JourneyStop: Decodable {
    let name: String
    let extId: String?
    let date: String?
    let time: String?

    /// Combines ResRobot's date and time into a Date.
    var dateTime: Date? {
        guard
            let date,
            let time
        else {
            return nil
        }

        let dateParts = date.split(separator: "-").compactMap {
            Int($0)
        }

        let timeParts = time.split(separator: ":").compactMap {
            Int($0)
        }

        guard
            dateParts.count == 3,
            timeParts.count >= 2
        else {
            return nil
        }

        var components = DateComponents()
        components.year = dateParts[0]
        components.month = dateParts[1]
        components.day = dateParts[2]
        components.hour = timeParts[0]
        components.minute = timeParts[1]
        components.second = timeParts.count > 2 ? timeParts[2] : 0

        return Calendar.current.date(from: components)
    }
}

struct JourneyProduct: Decodable {
    let name: String?
    let num: String?
    let displayNumber: String?
    let operatorName: String?
    let operatorCode: String?
    let categoryName: String?
    let categoryCode: String?

    enum CodingKeys: String, CodingKey {
        case name
        case num
        case displayNumber
        case operatorName = "operator"
        case operatorCode
        case categoryName = "catOutL"
        case categoryCode = "catOutS"
    }

    var displayName: String {
        let operatorValue = (operatorName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let transportOperator: String

        if operatorValue.localizedCaseInsensitiveContains(
            "Storstockholms Lokaltrafik"
        ) || operatorValue.localizedCaseInsensitiveCompare("SL") == .orderedSame {
            transportOperator = "SL"
        } else if operatorValue.localizedCaseInsensitiveContains(
            "Mälardalstrafik"
        ) || operatorValue.localizedCaseInsensitiveContains("Mälartåg") {
            transportOperator = "Mälardalstrafik"
        } else {
            transportOperator = operatorValue
        }

        let category = (categoryName ?? "").lowercased()

        let transportType: String

        if category.contains("buss") {
            transportType = "buss"
        } else if category.contains("tunnelbana") {
            transportType = "tunnelbana"
        } else if category.contains("spårvagn") {
            transportType = "spårvagn"
        } else if category.contains("tåg") {
            transportType = "tåg"
        } else {
            transportType = ""
        }

        let number = displayNumber ?? num

        if !transportOperator.isEmpty,
           !transportType.isEmpty,
           let number,
           !number.isEmpty {
            return "\(transportOperator) \(transportType) \(number)"
        }

        return name ?? transportOperator
    }

    // MARK: - Operator matching

    func matchesOperator(_ selectedOperator: String) -> Bool {
        let values = [
            operatorName,
            operatorCode,
            name
        ]
        .compactMap { $0 }
        .map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        }

        switch selectedOperator.lowercased() {
        case "sj":
            return values.contains {
                $0 == "sj"
                    || $0.hasPrefix("sj ")
                    || $0.contains("sj ab")
            }

        case "mälartåg":
            return values.contains {
                $0.contains("mälartåg")
                    || $0.contains("mälardalstrafik")
            }

        case "sl":
            return values.contains {
                $0 == "sl"
                    || $0.hasPrefix("sl ")
                    || $0.contains("storstockholms lokaltrafik")
            }

        case "ul":
            return values.contains {
                $0 == "ul"
                    || $0.hasPrefix("ul ")
                    || $0.contains("upplands lokaltrafik")
            }

        default:
            return values.contains {
                $0.localizedCaseInsensitiveContains(selectedOperator)
            }
        }
    }
}
