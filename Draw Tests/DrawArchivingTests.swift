
import XCTest
import AJRFoundation
@testable import Draw

class DrawArchivingTests: XCTestCase {

    func testDrawStrokeDash() throws {
        let dash = DrawStrokeDash(string: "1 1 2 1")

        let data = AJRXMLArchiver.archivedData(withRootObject: dash)
        XCTAssert(data != nil)
        if let data = data {
            if let string = String(data: data, encoding: .utf8) {
                print(string)
            }
            let newDash = try? AJRXMLUnarchiver.unarchivedObject(with: data)
            XCTAssert(newDash != nil)
            XCTAssert(dash.isEqual(to: newDash))
        }
    }

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
        let text = DrawTextAspect(graphic: graphic, text: NSAttributedString(string: "Now is the time for all good men to die."))

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
