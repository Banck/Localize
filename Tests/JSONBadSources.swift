//
//  JSONBadSources.swift
//  LocalizeTests
//
//  Copyright © 2019 @andresilvagomez.
//

import XCTest
import Localize

class JSONBadSources: XCTestCase {
    override func setUp() {
        super.setUp()
        Localize.update(provider: .json)
        Localize.update(bundle: Bundle(for: type(of: self)))
        Localize.update(language: "en")
        Localize.update(defaultLanguage: "rs")
    }

    func testLocalizeInAnyDictionary() {
        let localized = "heymomhowareyoy".localized
        XCTAssertEqual(localized, "heymomhowareyoy")
    }

    func testLocalizeProperty() {
        let localized = "hello.world".localized
        XCTAssertEqual(localized, "Hello world!")
    }

    func testLocalizeKey() {
        let localized = "hello.world".localize()
        XCTAssertEqual(localized, "Hello world!")
    }

    func testWithTableName() {
        let localized = "test.in.table".localize(tableName: "langTable")
        XCTAssertEqual(localized, "Test in table name")
    }

    func testWithBadTableName() {
        let localized = "test.in.table".localize(tableName: "langTablesss")
        XCTAssertEqual(localized, "test.in.table")
    }

    func testBadValueForKeyInLevels() {
        let localized = "test.in.table".localized
        XCTAssertEqual(localized, "test.in.table")
    }

    func testBadJSONFormat() {
        let localized = "test.in.table".localize(tableName: "badJSON")
        XCTAssertEqual(localized, "test.in.table")
    }

    func testNameForLanguage() {
        let localized = Localize.displayNameForLanguage("es")
        XCTAssertEqual(localized, "Spanish")
    }

    func testRestDefaultLang() {
        Localize.resetLanguage()
        XCTAssertTrue(true)
    }
}
