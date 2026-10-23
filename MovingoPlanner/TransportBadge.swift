//
//  TransportBadge.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-16.
//


import SwiftUI

struct TransportBadge: View {
    let leg: JourneyLeg

    private var product: JourneyProduct? {
        leg.Product?.first
    }

    private var operatorName: String {
        product?.operatorName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var category: String {
        product?.categoryName?.lowercased() ?? ""
    }

    private var lineNumber: String {
        (product?.displayNumber ?? product?.num ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedLine: String {
        lineNumber
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
    }

    private var isSL: Bool {
        operatorName.localizedCaseInsensitiveContains(
            "Storstockholms Lokaltrafik"
        ) || operatorName.localizedCaseInsensitiveCompare("SL") == .orderedSame
    }
    
    private var isUL: Bool {
        operatorName.localizedCaseInsensitiveCompare("UL") == .orderedSame
            || operatorName.localizedCaseInsensitiveContains(
                "Upplands Lokaltrafik"
            )
    }

    private var isULBus: Bool {
        isUL && (
            category.contains("buss")
            || category.contains("bus")
            || (product?.name ?? "")
                .localizedCaseInsensitiveContains("buss")
        )
    }

    private var isULMainLine: Bool {
        isULBus && (1...14).contains(Int(normalizedLine) ?? 0)
    }

    private var isMalartag: Bool {
        operatorName.localizedCaseInsensitiveContains("Mälardalstrafik")
            || operatorName.localizedCaseInsensitiveContains("Mälartåg")
            || (product?.name ?? "")
                .localizedCaseInsensitiveContains("Mälartåg")
    }
    
    private var isSJ: Bool {
        operatorName.localizedCaseInsensitiveContains("SJ")
    }

    private enum BadgeStyle {
        case commuterRail
        case metro
        case tram
        case bus
        case ulBus
        case ulMainBus
        case other
    }

    private var badgeStyle: BadgeStyle {
        // Mälartåg gets the commuter-rail shape, but in red.
        if isMalartag {
            return .commuterRail
        }
        
        if isSJ {
            return .commuterRail
        }

        if isULBus {
            return isULMainLine ? .ulMainBus : .ulBus
        }
        
        guard isSL else {
            return .other
        }

        // Check the category before the line number because
        // line 12 exists in both the metro and tram networks.
        if category.contains("tunnelbana") {
            return .metro
        }

        if category.contains("spårvagn")
            || category.contains("lokalbana") {
            return .tram
        }

        if category.contains("pendeltåg")
            || ["40", "41", "43", "48"].contains(normalizedLine) {
            return .commuterRail
        }

        if category.contains("buss") {
            return .bus
        }

        if ["11", "12", "13", "14", "17", "18", "19"]
            .contains(normalizedLine) {
            return .metro
        }

        if ["7", "12", "21", "25", "26", "27", "28", "29", "30", "31"]
            .contains(normalizedLine) {
            return .tram
        }

        // Useful fallback for SL bus lines such as 829.
        if !normalizedLine.isEmpty {
            return .bus
        }

        return .other
    }

    private var badgeColor: Color {
        if isMalartag {
            return Color(red: 0.85, green: 0.12, blue: 0.16)
        }
        
        if isSJ {
            return Color(red: 0.20, green: 0.78, blue: 0.35)
        }

        switch badgeStyle {
        case .commuterRail:
            return Color(red: 0.91, green: 0.31, blue: 0.60)

        case .metro:
            if ["17", "18", "19"].contains(normalizedLine) {
                return Color(red: 0.00, green: 0.60, blue: 0.31)
            }

            if ["13", "14"].contains(normalizedLine) {
                return Color(red: 0.94, green: 0.10, blue: 0.15)
            }

            return Color(red: 0.00, green: 0.55, blue: 0.82)

        case .tram:
            switch normalizedLine {
            case "7":
                return Color(red: 0.78, green: 0.80, blue: 0.78)
            case "12":
                return Color(red: 0.45, green: 0.55, blue: 0.63)
            case "21":
                return Color(red: 0.59, green: 0.35, blue: 0.20)
            case "30", "31":
                return Color(red: 0.96, green: 0.48, blue: 0.10)
            case "25", "26":
                return Color(red: 0.00, green: 0.68, blue: 0.69)
            case "27", "28", "29":
                return Color(red: 0.58, green: 0.25, blue: 0.61)
            default:
                return .gray
            }

        case .bus:
            return .black
            
        case .ulBus:
            return .black

        case .ulMainBus:
            return ulMainLineColor

        case .other:
            return .gray
        }
    }
    
    private var ulMainLineColor: Color {
        switch Int(normalizedLine) {
        case 1:
            return Color(red: 1, green: 1, blue: 1)
        case 2:
            return Color(red: 173 / 255, green: 15 / 255, blue: 10 / 255)
        case 3:
            return Color(red: 0 / 255, green: 150 / 255, blue: 65 / 255)
        case 4:
            return Color(red: 234 / 255, green: 82 / 255, blue: 151 / 255)
        case 5:
            return Color(red: 150 / 255, green: 184 / 255, blue: 55 / 255)
        case 6:
            return Color(red: 152 / 255, green: 118 / 255, blue: 80 / 255)
        case 7:
            return Color(red: 0 / 255, green: 182 / 255, blue: 237 / 255)
        case 8:
            return Color(red: 236 / 255, green: 102 / 255, blue: 8 / 255)
        case 9:
            return Color(red: 2 / 255, green: 129 / 255, blue: 201 / 255)
        case 10:
            return Color(red: 156 / 255, green: 26 / 255, blue: 129 / 255)
        case 11:
            return Color(red: 157 / 255, green: 157 / 255, blue: 156 / 255)
        case 12:
            return Color(red: 251 / 255, green: 186 / 255, blue: 0 / 255)
        case 13:
            return Color(red: 230 / 255, green: 204 / 255, blue: 228 / 255)
        case 14:
            return Color(red: 124 / 255, green: 202 / 255, blue: 219 / 255)
        default:
            return .black
        }
    }

    var body: some View {
        Group {
            if !lineNumber.isEmpty {
                Text(lineNumber)
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(
                        badgeStyle == .ulMainBus && normalizedLine == "1"
                            ? Color.black
                            : Color.white
                    )
                    .padding(.horizontal, badgeStyle == .commuterRail ? 7 : 6)
                    .frame(minWidth: 24, minHeight: 20)
                    .background(badgeColor)
                    .clipShape(badgeShape)
                    .fixedSize()
            }
        }
    }

    private var badgeShape: AnyShape {
        switch badgeStyle {
        case .commuterRail:
            return AnyShape(Capsule())

        case .metro:
            return AnyShape(RoundedRectangle(cornerRadius: 3))

        case .tram:
            return AnyShape(TramBadgeShape())

        case .ulMainBus:
            return AnyShape(Circle())

        case .bus, .ulBus, .other:
            return AnyShape(RoundedRectangle(cornerRadius: 3))
        }
    }
}

private struct TramBadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radiusX = min(4.0, rect.width / 2)
        let radiusY = min(12.0, rect.height / 2)

        var path = Path()

        path.move(to: CGPoint(x: radiusX, y: 0))

        // Top edge
        path.addLine(
            to: CGPoint(x: rect.maxX - radiusX, y: 0)
        )

        // Top-right corner
        path.addCurve(
            to: CGPoint(
                x: rect.maxX,
                y: radiusY
            ),
            control1: CGPoint(
                x: rect.maxX,
                y: 0
            ),
            control2: CGPoint(
                x: rect.maxX,
                y: radiusY
            )
        )

        // Right edge
        path.addLine(
            to: CGPoint(x: rect.maxX, y: rect.maxY - radiusY)
        )

        // Bottom-right corner
        path.addCurve(
            to: CGPoint(
                x: rect.maxX - radiusX,
                y: rect.maxY
            ),
            control1: CGPoint(
                x: rect.maxX,
                y: rect.maxY
            ),
            control2: CGPoint(
                x: rect.maxX - radiusX,
                y: rect.maxY
            )
        )

        // Bottom edge
        path.addLine(
            to: CGPoint(x: radiusX, y: rect.maxY)
        )

        // Bottom-left corner
        path.addCurve(
            to: CGPoint(
                x: 0,
                y: rect.maxY - radiusY
            ),
            control1: CGPoint(
                x: 0,
                y: rect.maxY
            ),
            control2: CGPoint(
                x: 0,
                y: rect.maxY - radiusY
            )
        )

        // Left edge
        path.addLine(
            to: CGPoint(x: 0, y: radiusY)
        )

        // Top-left corner
        path.addCurve(
            to: CGPoint(x: radiusX, y: 0),
            control1: CGPoint(x: 0, y: 0),
            control2: CGPoint(x: radiusX, y: 0)
        )

        path.closeSubpath()
        return path
    }
}
