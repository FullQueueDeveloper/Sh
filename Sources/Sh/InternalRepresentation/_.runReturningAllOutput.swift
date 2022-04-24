import Foundation

extension InternalRepresentation {
  
  func runReturningAllOutput() throws -> Process.AllOutput {
    announcer?.runReturningAllOutput(params.cmd)
    return try Process(params).runReturningAllOutput()
  }
  
  func runReturningAllOutput() async throws -> Process.AllOutput {
    announcer?.runReturningAllOutput(params.cmd)
    return try await Process(params).runReturningAllOutput()
  }
}