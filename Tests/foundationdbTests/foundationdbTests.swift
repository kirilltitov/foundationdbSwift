import XCTest
@testable import foundationdb

final class foundationdbTests: XCTestCase {
    func testOpenDatabase() {

        XCTAssertNoThrow(try Fdb.selectMaxApiVersion())
    }

    static var allTests = [
        ("openDatabase", testOpenDatabase),
    ]
}
