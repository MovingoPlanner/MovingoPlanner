//
//  APISettingsView.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-18.
//


import SwiftUI

struct APISettingsView: View {

    // MARK: - ResRobot State

    @State private var resRobotKey = ""
    @State private var showingResRobotKey = false
    @State private var testingResRobot = false
    @State private var resRobotStatus: String?
    @State private var resRobotSuccess = false

    // MARK: - Trafikverket State

    @State private var trafikverketKey = ""
    @State private var showingTrafikverketKey = false
    @State private var testingTrafikverket = false
    @State private var trafikverketStatus: String?
    @State private var trafikverketSuccess = false
    
    // MARK: - Trafiklab Realtime State

    @State private var realtimeKey = ""
    @State private var showingRealtimeKey = false
    @State private var testingRealtime = false
    @State private var realtimeStatus: String?
    @State private var realtimeSuccess = false

    // MARK: - API Key Status

    private var hasResRobotKey: Bool {
        APIKeyStore.shared.apiKey != nil ||
        hasEnvironmentKey("RESROBOT_API_KEY")
    }

    private var hasTrafikverketKey: Bool {
        APIKeyStore.shared.trafikverketApiKey != nil
    }
    
    private var hasRealtimeKey: Bool {
        APIKeyStore.shared.realtimeApiKey != nil
    }

    var body: some View {
        Form {

            // MARK: ResRobot

            Section {
                keyStatusRow(
                    title: "Status",
                    isConfigured: hasResRobotKey
                )

                keyInput(
                    title: "ResRobot API-nyckel",
                    text: $resRobotKey,
                    isVisible: $showingResRobotKey
                )

                Button {
                    saveResRobotKey()
                } label: {
                    Label(
                        "Spara ResRobot-nyckel",
                        systemImage: "checkmark.circle"
                    )
                }
                .disabled(isEmpty(resRobotKey))

                Button {
                    Task {
                        await testResRobotConnection()
                    }
                } label: {
                    HStack {
                        Label(
                            "Testa anslutning",
                            systemImage: "network"
                        )

                        Spacer()

                        if testingResRobot {
                            ProgressView()
                        }
                    }
                }
                .disabled(testingResRobot)

                if let resRobotStatus {
                    statusLabel(
                        resRobotStatus,
                        success: resRobotSuccess
                    )
                }

            } header: {
                Text("ResRobot")
            } footer: {
                Text(
                    "Används för att söka resor och hitta hållplatser. " +
                    "Nyckeln lagras säkert i iOS Keychain."
                )
            }

            
            // MARK: Trafikverket

            Section {
                keyStatusRow(
                    title: "Status",
                    isConfigured: hasTrafikverketKey
                )

                keyInput(
                    title: "Trafikverket API-nyckel",
                    text: $trafikverketKey,
                    isVisible: $showingTrafikverketKey
                )

                Button {
                    saveTrafikverketKey()
                } label: {
                    Label(
                        "Spara Trafikverket-nyckel",
                        systemImage: "checkmark.circle"
                    )
                }
                .disabled(isEmpty(trafikverketKey))

                Button {
                    Task {
                        await testTrafikverketConnection()
                    }
                } label: {
                    HStack {
                        Label(
                            "Testa anslutning",
                            systemImage: "network"
                        )

                        Spacer()

                        if testingTrafikverket {
                            ProgressView()
                        }
                    }
                }
                .disabled(testingTrafikverket || !hasTrafikverketKey)

                if let trafikverketStatus {
                    statusLabel(
                        trafikverketStatus,
                        success: trafikverketSuccess
                    )
                }

            } header: {
                Text("Trafikverket")
            } footer: {
                Text(
                    "Används för att hämta tågannonser och spårinformation. " +
                    "Nyckeln lagras säkert i iOS Keychain."
                )
            }
            
            // MARK: Trafiklab Realtime

            Section {
                keyStatusRow(
                    title: "Status",
                    isConfigured: hasRealtimeKey
                )

                keyInput(
                    title: "Trafiklab Realtime API-nyckel",
                    text: $realtimeKey,
                    isVisible: $showingRealtimeKey
                )

                Button {
                    saveRealtimeKey()
                } label: {
                    Label(
                        "Spara Realtime-nyckel",
                        systemImage: "checkmark.circle"
                    )
                }
                .disabled(isEmpty(realtimeKey))

                Button {
                    Task {
                        await testRealtimeConnection()
                    }
                } label: {
                    HStack {
                        Label(
                            "Testa anslutning",
                            systemImage: "network"
                        )

                        Spacer()

                        if testingRealtime {
                            ProgressView()
                        }
                    }
                }
                .disabled(testingRealtime || !hasRealtimeKey)

                if let realtimeStatus {
                    statusLabel(
                        realtimeStatus,
                        success: realtimeSuccess
                    )
                }

            } header: {
                Text("Trafiklab Realtime")
            } footer: {
                Text(
                    "Används för att hämta realtidsinformation om avgångar, " +
                    "förseningar och inställda avgångar. " +
                    "Nyckeln lagras säkert i iOS Keychain."
                )
            }

        }
        .navigationTitle("API-inställningar")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Reusable UI

    private func keyStatusRow(
        title: String,
        isConfigured: Bool
    ) -> some View {
        HStack {
            Text(title)

            Spacer()

            Text(isConfigured ? "Konfigurerad" : "Ej konfigurerad")
                .font(.caption.weight(.medium))
                .foregroundStyle(
                    isConfigured ? .green : .secondary
                )
        }
    }

    private func keyInput(
        title: String,
        text: Binding<String>,
        isVisible: Binding<Bool>
    ) -> some View {
        HStack(spacing: 10) {
            Group {
                if isVisible.wrappedValue {
                    TextField(title, text: text)
                } else {
                    SecureField(title, text: text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(
                    systemName: isVisible.wrappedValue
                        ? "eye.slash"
                        : "eye"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func statusLabel(
        _ message: String,
        success: Bool
    ) -> some View {
        Label(
            message,
            systemImage: success
                ? "checkmark.circle.fill"
                : "exclamationmark.circle.fill"
        )
        .font(.footnote)
        .foregroundStyle(success ? .green : .secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Helpers

    private func isEmpty(_ value: String) -> Bool {
        value.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    private func hasEnvironmentKey(_ name: String) -> Bool {
        !(ProcessInfo.processInfo.environment[name]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ?? true)
    }

    // MARK: - Save ResRobot

    private func saveResRobotKey() {
        do {
            try APIKeyStore.shared.save(resRobotKey)
            resRobotKey = ""

            resRobotStatus = "ResRobot-nyckeln sparades."
            resRobotSuccess = true
        } catch {
            resRobotStatus = error.localizedDescription
            resRobotSuccess = false
        }
    }

    // MARK: - Test ResRobot

    @MainActor
    private func testResRobotConnection() async {
        testingResRobot = true
        resRobotStatus = nil

        defer {
            testingResRobot = false
        }

        do {
            if !isEmpty(resRobotKey) {
                try APIKeyStore.shared.save(resRobotKey)
                resRobotKey = ""
            }

            guard hasResRobotKey else {
                throw ResRobotError.missingAPIKey
            }

            let stops = try await ResRobotService()
                .searchStops(query: "Stockholm")

            guard !stops.isEmpty else {
                throw ResRobotError.requestFailed(
                    "API:n svarade, men inga hållplatser hittades."
                )
            }

            resRobotStatus =
                "Anslutningen fungerar! " +
                "ResRobot skickade tillbaka \(stops.count) hållplatser."

            resRobotSuccess = true

        } catch {
            resRobotStatus = error.localizedDescription
            resRobotSuccess = false
        }
    }

    // MARK: - Save Trafikverket

    private func saveTrafikverketKey() {
        do {
            try APIKeyStore.shared.saveTrafikverketAPIKey(
                trafikverketKey
            )

            trafikverketKey = ""
            trafikverketStatus = "Trafikverket-nyckeln sparades."
            trafikverketSuccess = true
        } catch {
            trafikverketStatus = error.localizedDescription
            trafikverketSuccess = false
        }
    }

    // MARK: - Test Trafikverket

    @MainActor
    private func testTrafikverketConnection() async {
        testingTrafikverket = true
        trafikverketStatus = nil

        defer {
            testingTrafikverket = false
        }

        do {
            if !isEmpty(trafikverketKey) {
                try APIKeyStore.shared.saveTrafikverketAPIKey(
                    trafikverketKey
                )
                trafikverketKey = ""
            }

            guard APIKeyStore.shared.trafikverketApiKey != nil else {
                throw APIKeyError.emptyKey
            }

            let message = try await TrafikverketService.shared.testConnection()

            trafikverketStatus = message
            trafikverketSuccess = true

        } catch {
            trafikverketStatus = error.localizedDescription
            trafikverketSuccess = false
        }
    }
    
    // MARK: - Save Realtime

    private func saveRealtimeKey() {
        do {
            try APIKeyStore.shared.saveRealtimeAPIKey(realtimeKey)

            realtimeKey = ""
            realtimeStatus = "Realtime-nyckeln sparades."
            realtimeSuccess = true

        } catch {
            realtimeStatus = error.localizedDescription
            realtimeSuccess = false
        }
    }

    // MARK: - Test Realtime

    @MainActor
    private func testRealtimeConnection() async {
        testingRealtime = true
        realtimeStatus = nil

        defer {
            testingRealtime = false
        }

        do {
            if !isEmpty(realtimeKey) {
                try APIKeyStore.shared.saveRealtimeAPIKey(realtimeKey)
                realtimeKey = ""
            }

            guard APIKeyStore.shared.realtimeApiKey != nil else {
                throw APIKeyError.emptyKey
            }

            // We'll connect this to the actual departures
            // endpoint once we implement the departure-board service.

            realtimeStatus = "API-nyckeln finns sparad."
            realtimeSuccess = true

        } catch {
            realtimeStatus = error.localizedDescription
            realtimeSuccess = false
        }
    }
}
