import Foundation

/// Pure rules for the one-time free allowance.
/// Persistence stays in `FreeAllowanceLedger`; this type owns the credit decisions.
enum FreeAllowancePolicy {
    static let totalCredits = 3
    static let ledgerSchemaVersion = 1

    static func clampUsedTasks(
        _ usedTasks: Int,
        totalCredits: Int = totalCredits
    ) -> Int {
        min(max(0, usedTasks), totalCredits)
    }

    /// Monotonic merge used by bootstrap and checkpoint operations.
    /// A stale caller can never restore already-consumed credits.
    static func mergedUsedTasks(
        existingUsedTasks: Int?,
        candidateUsedTasks: Int,
        totalCredits: Int = totalCredits
    ) -> (usedTasks: Int, didIncrease: Bool) {
        let candidate = clampUsedTasks(candidateUsedTasks, totalCredits: totalCredits)

        guard let existingUsedTasks else {
            return (candidate, true)
        }

        let existing = clampUsedTasks(existingUsedTasks, totalCredits: totalCredits)
        let merged = max(existing, candidate)
        return (merged, merged > existing)
    }

    static func remainingCredits(
        usedTasks: Int,
        totalCredits: Int = totalCredits
    ) -> Int {
        totalCredits - clampUsedTasks(usedTasks, totalCredits: totalCredits)
    }

    static func canStartSolve(
        usedTasks: Int,
        totalCredits: Int = totalCredits
    ) -> Bool {
        remainingCredits(usedTasks: usedTasks, totalCredits: totalCredits) > 0
    }

    /// Advances usage exactly once after a task has produced a successful solution.
    static func usedTasksAfterSuccessfulSolve(
        _ usedTasks: Int,
        totalCredits: Int = totalCredits
    ) -> Int {
        let current = clampUsedTasks(usedTasks, totalCredits: totalCredits)
        return current < totalCredits ? current + 1 : current
    }

    static func validatedSnapshot(
        version: Int,
        usedTasks: Int,
        lastUpdatedAt: Date,
        schemaVersion: Int = ledgerSchemaVersion,
        totalCredits: Int = totalCredits
    ) -> Result<FreeAllowanceSnapshot, FreeAllowanceLedgerError> {
        guard version == schemaVersion else {
            return .failure(.unsupportedVersion(version))
        }

        guard (0...totalCredits).contains(usedTasks),
              lastUpdatedAt.timeIntervalSince1970.isFinite else {
            return .failure(.corruptData)
        }

        return .success(
            FreeAllowanceSnapshot(
                version: version,
                usedTasks: usedTasks,
                lastUpdatedAt: lastUpdatedAt
            )
        )
    }
}
