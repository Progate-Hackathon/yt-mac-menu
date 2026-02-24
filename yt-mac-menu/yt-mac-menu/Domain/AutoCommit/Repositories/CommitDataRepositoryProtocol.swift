import Foundation
import Combine

protocol CommitDataRepositoryProtocol {
    func sendCommitData(_ data: CommitDataModel) async throws -> CommitSuccessModel
}
