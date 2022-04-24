// sh.swift
//
// Public functions for general use.
// For quiet versions of these functions, see `shq.swift`

import Foundation
import FoundationExtensions
import Rainbow

/// Run a shell command. Useful for obtaining small bits of output
/// from a shell program
///
/// Announces the command it is about to execute. To run quietly,
/// use `shq`
///
/// Arguments:
/// - `cmd` the shell command to run
/// - `environment` a dictionary of enviroment variables to merge
///     with the enviroment of the current `Process`
/// - `workingDirectory` the directory where to run the command
///
/// Returns:
/// - `String` of whatever is in the standard output buffer.
///     Uses `.trimmingCharacters(in: .whitespacesAndNewlines)`
///
public func sh(_ cmd: String,
               environment: [String: String] = [:],
               workingDirectory: String? = nil) throws -> String? {
  try InternalRepresetation(announcer: .init(),
                            cmd: cmd,
                            environment: environment,
                            workingDirectory: workingDirectory)
    .runReturningTrimmedString()
}

/// `Async`/`await` version
public func sh(_ cmd: String,
               environment: [String: String] = [:],
               workingDirectory: String? = nil) async throws -> String? {
  try await InternalRepresetation(announcer: .init(),
                            cmd: cmd,
                            environment: environment,
                            workingDirectory: workingDirectory)
  .runReturningTrimmedString()
}


/// Run a shell command, and parse the output as JSON
///
public func sh<D: Decodable>(_ type: D.Type,
                             _ cmd: String,
                             environment: [String: String] = [:],
                             workingDirectory: String? = nil,
                             using jsonDecoder: JSONDecoder = .init()) throws -> D {
  try InternalRepresetation(announcer: .init(),
                            cmd: cmd,
                            environment: environment,
                            workingDirectory: workingDirectory)
  .runDecoding(type, using: jsonDecoder)
}

/// `Async`/`await` version
public func sh<D: Decodable>(_ type: D.Type,
                             _ cmd: String,
                             environment: [String: String] = [:],
                             workingDirectory: String? = nil) async throws -> D {
  await announce("Running `\(cmd)`, decoding `\(type)`")

  return try await shq(type, cmd, environment: environment, workingDirectory: workingDirectory)
}


/// Run a shell command, sending output to the terminal or a file.
/// Useful for long running shell commands like `xcodebuild`
///
/// Announces the command it is about to execute. To run quietly,
/// use `shq`
///
/// Arguments:
/// - `sink` where to redirect output to, either `.terminal` or `.file(path)`
/// - `cmd` the shell command to run
/// - `environment` a dictionary of enviroment variables to merge
///     with the enviroment of the current `Process`
/// - `workingDirectory` the directory where to run the command
///
public func sh(_ sink: Sink,
               _ cmd: String,
               environment: [String: String] = [:],
               workingDirectory: String? = nil) throws {

  switch sink {
  case .terminal:
    announce("Running `\(cmd)`")
  case .file(let path):
    announce("Running `\(cmd)`, logging to `\(path.blue)`")
  case .null:
    announce("Running `\(cmd)`, discarding output")
  }

  try shq(sink, cmd, environment: environment, workingDirectory: workingDirectory)
}

/// `Async`/`await` version
public func sh(_ sink: Sink,
               _ cmd: String,
               environment: [String: String] = [:],
               workingDirectory: String? = nil) async throws {

  switch sink {
  case .terminal:
    await announce("Running `\(cmd)`")
  case .file(let path):
    await announce("Running `\(cmd)`, logging to `\(path.blue)`")
  case .null:
    await announce("Running `\(cmd)`, discarding output")
  }

  try await shq(sink, cmd, environment: environment, workingDirectory: workingDirectory)
}

private func announce(_ text: String) {
  ("[Sh] ".blue + text + "\n")
    .data(using: .utf8)
    .map(FileHandle.standardError.write)
}

private func announce(_ text: String) async {
  await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
    ("[Sh] ".blue + text + "\n")
      .data(using: .utf8)
      .map(FileHandle.standardError.write)
    continuation.resume()
  }
}
