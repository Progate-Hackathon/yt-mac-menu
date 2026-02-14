import Foundation
import Combine

class CommitDataRepository: CommitDataRepositoryProtocol {
    func sendCommitData(_ data: CommitDataModel) async throws {
        print("✅ コミットデータ送信: \(data)")
    }
}
