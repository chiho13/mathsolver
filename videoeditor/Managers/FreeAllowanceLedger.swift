import Foundation
import Security

struct FreeAllowanceSnapshot: Codable, Equatable {
    let version: Int
    let usedTasks: Int
    let lastUpdatedAt: Date
}

enum FreeAllowanceLedgerError: Error, Equatable {
    case keychain(OSStatus)
    case corruptData
    case unsupportedVersion(Int)
}

enum FreeAllowanceLedgerLoadResult: Equatable {
    case missing
    case available(FreeAllowanceSnapshot)
    case unavailable(FreeAllowanceLedgerError)
}

protocol FreeAllowanceLedgerProviding {
    func load() -> FreeAllowanceLedgerLoadResult
    func bootstrap(usedTasks: Int, now: Date) -> FreeAllowanceLedgerLoadResult
    func checkpoint(usedTasks: Int, now: Date) -> FreeAllowanceLedgerLoadResult
}

/// Authoritative, non-synchronizable storage for the one-time free allowance.
/// Keychain data remains available after a normal app deletion and reinstall on the same device.
final class FreeAllowanceLedger: FreeAllowanceLedgerProviding {
    static let shared = FreeAllowanceLedger()

    private static let service = "com.anthonyho.mathsolver.free-allowance"
    private static let account = "successful-solves-v1"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func load() -> FreeAllowanceLedgerLoadResult {
        loadStoredSnapshot()
    }

    func bootstrap(usedTasks: Int, now: Date) -> FreeAllowanceLedgerLoadResult {
        saveMerged(candidateUsedTasks: usedTasks, now: now)
    }

    func checkpoint(usedTasks: Int, now: Date) -> FreeAllowanceLedgerLoadResult {
        saveMerged(candidateUsedTasks: usedTasks, now: now)
    }

#if DEBUG
    /// Removes the persisted allowance so the next bootstrap starts with all
    /// free credits available. This is intentionally unavailable in Release.
    @discardableResult
    func resetForDebug() -> Bool {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
#endif

    private func saveMerged(
        candidateUsedTasks: Int,
        now: Date
    ) -> FreeAllowanceLedgerLoadResult {
        switch loadStoredSnapshot() {
        case .missing:
            let merged = FreeAllowancePolicy.mergedUsedTasks(
                existingUsedTasks: nil,
                candidateUsedTasks: candidateUsedTasks
            )
            return save(makeSnapshot(usedTasks: merged.usedTasks, lastUpdatedAt: now))

        case .available(let snapshot):
            let merged = FreeAllowancePolicy.mergedUsedTasks(
                existingUsedTasks: snapshot.usedTasks,
                candidateUsedTasks: candidateUsedTasks
            )
            guard merged.didIncrease else {
                return .available(snapshot)
            }
            return save(
                makeSnapshot(
                    usedTasks: merged.usedTasks,
                    lastUpdatedAt: max(now, snapshot.lastUpdatedAt)
                )
            )

        case .unavailable(let error):
            return .unavailable(error)
        }
    }

    private func loadStoredSnapshot() -> FreeAllowanceLedgerLoadResult {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return status == errSecItemNotFound
                ? .missing
                : .unavailable(.keychain(status))
        }

        guard let data = result as? Data,
              let decoded = try? decoder.decode(FreeAllowanceSnapshot.self, from: data) else {
            return .unavailable(.corruptData)
        }

        switch FreeAllowancePolicy.validatedSnapshot(
            version: decoded.version,
            usedTasks: decoded.usedTasks,
            lastUpdatedAt: decoded.lastUpdatedAt
        ) {
        case .success(let snapshot):
            return .available(snapshot)
        case .failure(let error):
            return .unavailable(error)
        }
    }

    private func save(_ snapshot: FreeAllowanceSnapshot) -> FreeAllowanceLedgerLoadResult {
        guard let data = try? encoder.encode(snapshot) else {
            return .unavailable(.corruptData)
        }

        let query = baseQuery()
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return .available(snapshot)
        }

        guard updateStatus == errSecItemNotFound else {
            return .unavailable(.keychain(updateStatus))
        }

        var addQuery = query
        addQuery.merge(attributes) { _, newValue in newValue }

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        return addStatus == errSecSuccess
            ? .available(snapshot)
            : .unavailable(.keychain(addStatus))
    }

    private func makeSnapshot(
        usedTasks: Int,
        lastUpdatedAt: Date
    ) -> FreeAllowanceSnapshot {
        FreeAllowanceSnapshot(
            version: FreeAllowancePolicy.ledgerSchemaVersion,
            usedTasks: FreeAllowancePolicy.clampUsedTasks(usedTasks),
            lastUpdatedAt: lastUpdatedAt
        )
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecAttrSynchronizable as String: false
        ]
    }
}
