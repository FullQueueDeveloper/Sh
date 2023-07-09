import XCTest
import Foundation
@testable import Sh

final class LogFileTests: XCTestCase {

  func testSimple() throws {
    try sh(.file("/tmp/sh-test.log"), #"echo "simple""#)
    XCTAssertEqual(try String(contentsOfFile: "/tmp/sh-test.log"), "simple\n")
  }

  func testSimpleAsync() async throws {
    try await sh(.file("/tmp/sh-test.log"), #"echo "simple""#)
    XCTAssertEqual(try String(contentsOfFile: "/tmp/sh-test.log"), "simple\n")
  }

   func testPrintingErrorWhenFileOutputIsShort() throws {
     do {
       try sh(.file("/tmp/sh-test.log"), #"echo "simple" > /unknown/path/name"#)
       XCTFail("Expected the above to throw an `Errors.errorWithLogInfo`")
     } catch Errors.errorWithLogInfo(let logInfo, underlyingError: let underlyingError) {

       XCTAssertTrue(logInfo.contains("/unknown/path/name"))

       let terminationError = try XCTUnwrap(underlyingError as? TerminationError)

       XCTAssertNotEqual(terminationError.status, 0)
       XCTAssertEqual(terminationError.reason, "`regular exit`")

       let error = Errors.errorWithLogInfo(logInfo, underlyingError: underlyingError)
       XCTAssertTrue(error.localizedDescription.contains("/unknown/path/name"))
     } catch {
       XCTFail("Expected the above to throw an `Errors.errorWithLogInfo`, instead got an \(error)")
     }
   }

  func testPrintingErrorWhenFileOutputIsLong() throws {
    do {
      try sh(.file("/tmp/sh-test.log"), """
      swift test --package-path Fixtures/SwiftProjectWithFailingTests
      """)
      XCTFail("Expected the above to throw an `Errors.errorWithLogInfo`")
    } catch Errors.errorWithLogInfo(let logInfo, underlyingError: let underlyingError) {

      XCTAssertTrue(logInfo.contains(#"XCTAssertEqual failed: ("Some name") is not equal to ("Wrong name")"#))

      let terminationError = try XCTUnwrap(underlyingError as? TerminationError)

      XCTAssertNotEqual(terminationError.status, 0)
      XCTAssertEqual(terminationError.reason, "`regular exit`")

      let error = Errors.errorWithLogInfo(logInfo, underlyingError: underlyingError)
      XCTAssertTrue(error.localizedDescription.contains(#"XCTAssertEqual failed: ("Some name") is not equal to ("Wrong name")"#))

    } catch {
      XCTFail("Expected the above to throw an `Errors.errorWithLogInfo`, instead got an \(error)")
    }
  }

  func testCreatesMissingLogfiles() throws {

    do {
      try sh(.file("/tmp/missing/path/sh-test.log"), #"echo "simple" > /unknown/path/name"#)
    } catch Errors.errorWithLogInfo(let info, underlyingError: let underlyingError) {
      XCTAssertEqual(info, "/bin/sh: /unknown/path/name: No such file or directory")
      XCTAssertEqual(underlyingError.localizedDescription, "Ended with status 1 with reason: `regular exit`")
    } catch {
      XCTFail("Expected an errorWithLogInfo, but got \(error)")
    }
  }

  func testUnwritableLogfile() throws {
    do {
      try sh(.file("/missing/path/sh-test.log"), #"echo "simple" > /unknown/path/name"#)
    } catch Errors.openingLogError(let logError, underlyingError: let underlyingError) {

      XCTAssertEqual(logError.localizedDescription, "Ended with status 1 with reason: `regular exit`")
      XCTAssertEqual(underlyingError.localizedDescription, "You can’t save the file “path” because the volume is read only.")
    } catch {
      XCTFail("Expected an opening log error, but got \(error)")
    }
  }
}
