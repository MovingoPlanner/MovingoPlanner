//
//  APIKeyStore.swift
//  MovingoPlanner
//
//  Created by Sixten Ståby on 2026-10-17.
//


import Foundation
import Security

final class APIKeyStore {
    static let shared = APIKeyStore()

    private let service =
        Bundle.main.bundleIdentifier ?? "MovingoPlanner"

    private let account = "RESROBOT_API_KEY"
    private let realtimeAccount = "TRAFIKLAB_REALTIME_API_KEY"
    private let trafikverketAccount = "TRAFIKVERKET_API_KEY"

    private init() {}

    // MARK: - ResRobot API Key

    var apiKey: String? {
        readKey(for: account)
    }

    func save(_ key: String) throws {
        try saveKey(key, for: account)
    }

    func delete() throws {
        try deleteKey(for: account)
    }

    // MARK: - Trafiklab Realtime API Key
    // Keep temporarily until the replacement is working.

    var realtimeApiKey: String? {
        readKey(for: realtimeAccount)
    }

    func saveRealtimeAPIKey(_ key: String) throws {
        try saveKey(key, for: realtimeAccount)
    }

    func deleteRealtimeAPIKey() throws {
        try deleteKey(for: realtimeAccount)
    }

    // MARK: - Trafikverket API Key

    var trafikverketApiKey: String? {
        readKey(for: trafikverketAccount)
    }

    func saveTrafikverketAPIKey(_ key: String) throws {
        try saveKey(key, for: trafikverketAccount)
    }

    func deleteTrafikverketAPIKey() throws {
        try deleteKey(for: trafikverketAccount)
    }

    // MARK: - Shared Keychain Helpers

    private func readKey(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else {
            return nil
        }

        return key
    }

    private func saveKey(
        _ key: String,
        for account: String
    ) throws {
        let trimmedKey = key.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedKey.isEmpty else {
            throw APIKeyError.emptyKey
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let data = Data(trimmedKey.utf8)

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecItemNotFound {
            var newItem = query

            attributes.forEach {
                newItem[$0.key] = $0.value
            }

            let addStatus = SecItemAdd(
                newItem as CFDictionary,
                nil
            )

            guard addStatus == errSecSuccess else {
                throw APIKeyError.keychainError(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw APIKeyError.keychainError(updateStatus)
        }
    }

    private func deleteKey(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess ||
              status == errSecItemNotFound else {
            throw APIKeyError.keychainError(status)
        }
    }
}

enum APIKeyError: LocalizedError {
    case emptyKey
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "Enter an API key before saving."

        case .keychainError(let status):
            return "Could not access Keychain. Error: \(status)"
        }
    }
}
