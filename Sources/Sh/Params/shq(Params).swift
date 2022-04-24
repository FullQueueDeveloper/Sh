/// shq.swift
///
/// Public functions for general use.
///
/// These are the quiet versions of the functions in `sh(Params).swift`.
///
/// For `async`/`await` versions, see `shq(Params) async.swift`

import Foundation

/// Run a shell command. Useful for obtaining small bits of output
/// from a shell program
///
/// Does not announce the command it is about to execute.
/// To get an announcement, use `sh`
///
/// Arguments:
/// - `cmd` the shell command to run
/// - `environment` a dictionary of enviroment variables to merge
///     with the enviroment of the current `Process`
/// - `workingDirectory` the directory where to run the command
///
/// Returns:
/// - `String?` of whatever is in the standard output buffer.
///     Calls `.trimmingCharacters(in: .whitespacesAndNewlines)`
///
public func shq(_ params: Params) throws -> String?  {
  try
  InternalRepresentation(announcer: nil,
                        params: params)
  .runReturningTrimmedString()
}

/// Run a shell command, and parse the output as JSON
///
public func shq<D: Decodable>(_ type: D.Type,
                              using jsonDecoder: JSONDecoder = .init(),
                              _ params: Params) throws -> D {
  try
  InternalRepresentation(announcer: nil,
                        params: params)
  .runDecoding(type, using: jsonDecoder)
}

/// Run a shell command, sending output to the terminal or a file.
/// Useful for long running shell commands like `xcodebuild`
///
/// Does not announce the command it is about to execute.
/// To get an announcement, use `sh`
///
/// Arguments:
/// - `sink` where to redirect output to, either `.terminal` or `.file(path)`
/// - `cmd` the shell command to run
/// - `environment` a dictionary of enviroment variables to merge
///     with the enviroment of the current `Process`
/// - `workingDirectory` the directory where to run the command
///
public func shq(_ sink: Sink,
                _ params: Params) throws {
  try
  InternalRepresentation(announcer: nil,
                        params: params)
  .runRedirectingStreams(to: sink)
}