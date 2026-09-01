import Foundation
import Testing
@testable import videoeditor

struct FreeAllowancePolicyTests {
    @Test func grantsExactlyThreeCredits() {
        #expect(FreeAllowancePolicy.totalCredits == 3)
        #expect(FreeAllowancePolicy.remainingCredits(usedTasks: 0) == 3)
    }

    @Test func successfulSolvesConsumeOneCreditAndClampAtZero() {
        let afterFirst = FreeAllowancePolicy.usedTasksAfterSuccessfulSolve(0)
        let afterSecond = FreeAllowancePolicy.usedTasksAfterSuccessfulSolve(afterFirst)
        let afterThird = FreeAllowancePolicy.usedTasksAfterSuccessfulSolve(afterSecond)
        let afterFourth = FreeAllowancePolicy.usedTasksAfterSuccessfulSolve(afterThird)

        #expect(FreeAllowancePolicy.remainingCredits(usedTasks: afterFirst) == 2)
        #expect(FreeAllowancePolicy.remainingCredits(usedTasks: afterSecond) == 1)
        #expect(FreeAllowancePolicy.remainingCredits(usedTasks: afterThird) == 0)
        #expect(afterFourth == afterThird)
        #expect(!FreeAllowancePolicy.canStartSolve(usedTasks: afterThird))
    }

    @Test func mergeNeverRestoresConsumedCredits() {
        let staleCandidate = FreeAllowancePolicy.mergedUsedTasks(
            existingUsedTasks: 2,
            candidateUsedTasks: 1
        )
        let newerCandidate = FreeAllowancePolicy.mergedUsedTasks(
            existingUsedTasks: 1,
            candidateUsedTasks: 2
        )

        #expect(staleCandidate.usedTasks == 2)
        #expect(!staleCandidate.didIncrease)
        #expect(newerCandidate.usedTasks == 2)
        #expect(newerCandidate.didIncrease)
    }

    @Test func rejectsInvalidOrUnsupportedSnapshots() {
        let now = Date()

        #expect(
            FreeAllowancePolicy.validatedSnapshot(
                version: FreeAllowancePolicy.ledgerSchemaVersion,
                usedTasks: 4,
                lastUpdatedAt: now
            ) == .failure(.corruptData)
        )
        #expect(
            FreeAllowancePolicy.validatedSnapshot(
                version: 99,
                usedTasks: 0,
                lastUpdatedAt: now
            ) == .failure(.unsupportedVersion(99))
        )
    }
}
