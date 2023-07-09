import Foundation
import XCTest
@testable import Sh

// These are having issues running in the full suite of tests?

final class AsyncTests: XCTestCase {

  func testSimpleAsync() async throws {
    let process = Process(cmd: #"echo simple"#)
    let allOutput = try await process.runReturningAllOutput()

    XCTAssertEqual(allOutput.stdOut.asTrimmedString(), "simple")
    XCTAssertEqual(allOutput.stdErr, Data())
    XCTAssertNil(allOutput.terminationError)
  }

  func testCustomDecodeJsonOutputAsync() async throws {
    let json = #"'[{"type":"start","date":"2022-10-29T19:22:22Z"},{"type":"stop","date":"2023-10-29T19:22:22Z"}]'"#

    struct Event: Decodable {
      let type: String
      let date: Date
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let events = try await sh([Event].self, decodedBy: decoder, "echo \(json)")
    XCTAssertEqual(events.count, 2)
    XCTAssertEqual(events.first?.type, "start")
    XCTAssertEqual(events.first?.date.timeIntervalSince1970, 1667071342)
    XCTAssertEqual(events.last?.type, "stop")
    XCTAssertEqual(events.last?.date.timeIntervalSince1970, 1698607342)
  }
}
