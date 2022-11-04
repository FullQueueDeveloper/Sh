import XCTest
@testable import Sh

final class LogFileTests: XCTestCase {

  func testSimple() throws {

    do {
      try sh(.file("/tmp/sh-test.log"), #"echo "simple" > /unknown/path/name"#)
      XCTFail("Expected the above to throw an `Errors.errorWithLogInfo`")
    } catch Errors.errorWithLogInfo(let logInfo, underlyingError: let underlyingError) {

      XCTAssertTrue(logInfo.contains("/unknown/path/name"))

      let terminationError = try XCTUnwrap(underlyingError as? TerminationError)

      XCTAssertNotEqual(terminationError.status, 0)
      XCTAssertEqual(terminationError.reason, "`regular exit`")
    } catch {
      XCTFail("Expected the above to throw an `Errors.errorWithLogInfo`, instead got an \(error)")
    }
  }

  func testUnwritableLogfile() throws {
    do {
      try sh(.file("/missing/path/sh-test.log"), #"echo "simple" > /unknown/path/name"#)
    } catch Errors.openingLogError(let logError, underlyingError: let underlyingError) {
      XCTAssertEqual(logError.localizedDescription, "The file “sh-test.log” couldn’t be opened because there is no such file.")

      XCTAssertTrue(underlyingError.localizedDescription.contains("CouldNotCreateFile error"))
      
    } catch {
      XCTFail("Expected an opening log error, but got \(error)")
    }
  }
}
