import XCTest
@testable import foundationdb

final class foundationdbTests: XCTestCase {
    func openDatabase() {

        XCTAssertNoThrow(try Fdb.selectMaxApiVersion())
    }

    static var allTests = [
        ("openDatabase", openDatabase),
    ]
}
