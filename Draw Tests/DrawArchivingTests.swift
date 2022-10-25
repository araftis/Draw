/*
DrawArchivingTests.swift
Draw

Copyright © 2021, AJ Raftis and AJRFoundation authors
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this 
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, 
  this list of conditions and the following disclaimer in the documentation 
  and/or other materials provided with the distribution.
* Neither the name of Draw nor the names of its contributors may be 
  used to endorse or promote products derived from this software without 
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL AJ RAFTIS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import XCTest
import AJRFoundation
@testable import Draw

class DrawArchivingTests: XCTestCase {

    func testDrawLinkCap() throws {
        let linkCaps = [DrawLinkCapArrow(), DrawLinkCapCircle(), DrawLinkCapDiamond(), DrawLinkCapDoubleArrow(), DrawLinkCapSquare()]

        for linkCap in linkCaps {
            let data = AJRXMLArchiver.archivedData(withRootObject: linkCap)
            XCTAssert(data != nil)
            if let data = data {
                if let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
                let newLinkCap = try? AJRXMLUnarchiver.unarchivedObject(with: data)
                XCTAssert(newLinkCap != nil)
                XCTAssert(linkCap.isEqual(to: newLinkCap))
            }
        }
    }

    func buildTestPath() -> AJRBezierPath {
        let path = AJRBezierPath();
        path.move(to: CGPoint(x: -10, y: -10))
        path.line(to: CGPoint(x: -10, y: 10))
        path.line(to: CGPoint(x: 10, y: 10))
        path.line(to: CGPoint(x: 10, y: -10))
        path.close()

        return path
    }

    func testDrawGraphics() throws {
        var graphics : [DrawGraphic] = [DrawCircle(frame: NSRect(x: 10, y: 10, width: 100, height: 100)),
                                        DrawPen(frame: NSRect.zero, path: buildTestPath()),
                                        DrawSquiggle(frame: NSRect.zero, path: buildTestPath()),
                                        DrawRectangle(frame: NSRect(x: 10, y: 10, width: 100, height: 100))]

        let sourceGraphic = DrawCircle(frame: NSRect(x: 10, y: 10, width: 100, height: 100));
        let destinationGraphic = DrawPen(frame: NSRect.zero, path: buildTestPath());
        let drawLink = DrawLink(source: sourceGraphic)
        drawLink.destination = destinationGraphic
        drawLink.sourceCap = DrawLinkCapArrow()
        drawLink.destinationCap = DrawLinkCapCircle()
        graphics.append(drawLink)

        for graphic in graphics {
            let data = AJRXMLArchiver.archivedData(withRootObject: graphic)
            XCTAssert(data != nil)
            if let data = data {
                if let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
                let newGraphic = try? AJRXMLUnarchiver.unarchivedObject(with: data)
                XCTAssert(newGraphic != nil)
                XCTAssert(graphic.isEqual(newGraphic), "graphic \(graphic) wasn't equal to decoded.")
            }
        }
    }

    func testDrawText() throws {
        let graphic = DrawCircle(frame: NSRect(x: 10, y: 10, width: 100, height: 100))
        let text = DrawText(graphic: graphic, text: NSAttributedString(string: "Now is the time for all good men to die."))

        graphic.addAspect(text, with: .afterBackground)

        let data = AJRXMLArchiver.archivedData(withRootObject: graphic)
        XCTAssert(data != nil)
        if let data = data {
            if let string = String(data: data, encoding: .utf8) {
                print(string)
            }
            let newGraphic = try? AJRXMLUnarchiver.unarchivedObject(with: data)
            XCTAssert(newGraphic != nil)
            XCTAssert(graphic.isEqual(newGraphic), "graphic \(graphic) wasn't equal to decoded.")
        }
    }

    func testDocument() throws {
        let document = try? DrawDocument(type: "com.ajr.papel")

        XCTAssert(document != nil, "Failed to create document.")

        if let document = document {
            let data = AJRXMLArchiver.archivedData(withRootObject: document.storage)
            XCTAssert(data != nil, "Document failed to archive.")
            if let data = data {
                if let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
                let storage = try? AJRXMLUnarchiver.unarchivedObject(with: data)
                XCTAssert(storage != nil)
                XCTAssert(storage is DrawDocumentStorage)
            }
        }
    }
}
