import XCTest

import foundationdbTests

var tests = [XCTestCaseEntry]()
tests += foundationdbTests.allTests()
XCTMain(tests)