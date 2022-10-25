//
//  DrawStrokeDashTests.swift
//  Draw Tests
//
//  Created by AJ Raftis on 10/24/22.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import Foundation

import XCTest
import AJRFoundation
@testable import Draw

class DrawStrokeDashTests: XCTestCase {

    func testDrawStrokeDash() throws {
        let stroke = DrawStroke()
        let dash = DrawStrokeDash(string: "1 1 2 1")
        stroke.dash = dash

        let data = AJRXMLArchiver.archivedData(withRootObject: stroke)
        XCTAssert(data != nil)
        if let data = data {
            if let string = String(data: data, encoding: .utf8) {
                print(string)
            }
            let newStroke = try? AJRXMLUnarchiver.unarchivedObject(with: data)
            XCTAssert(newStroke != nil)
            XCTAssert(AJRAnyEquals(stroke, newStroke))
        }
    }
    
    func testStringConversion() throws {
    }

}

