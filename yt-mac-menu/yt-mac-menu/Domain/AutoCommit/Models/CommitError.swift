enum CommitError: Error {
    case remoteError(message: String, detail: String?)
    case networkError(Error)
    case unknown
}
