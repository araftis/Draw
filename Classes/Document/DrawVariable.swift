//
//  DrawVariable.swift
//  Draw
//
//  Created by AJ Raftis on 10/18/22.
//  Copyright © 2022 Apple, Inc. All rights reserved.
//

import AJRFoundation

@objcMembers
open class DrawVariable: AJRVariable {

    // These define the "scope" of the variable. Generally, a variable must belong to a document, but it may also belong to a layer, page, or graphic.
    open var document : DrawDocument?
    open var layer : DrawLayer?
    open var page : DrawPage?
    open var graphic : DrawGraphic?

    // MARK: - Creation

    required public init() {
        super.init(name: AJRVariable.UnsetPlaceholderName)
    }

    public init(name: String, value: AJREvaluation?, document: DrawDocument) {
        self.document = document
        super.init(name: name, value: value)
    }

    // NSCoding

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) should never be called on \(type(of:self))")
    }

    // MARK: - AJREquatable

    open override func isEqual(to object: Any?) -> Bool {
        if let object = object as? DrawVariable {
            return (super.isEqual(to: object)
                    && document === object.document
                    && layer == object.layer
                    && page == object.page
                    && graphic == object.graphic)
        }
        return false
    }

    // MARK: - AJRXMLCoding

    // We don't actually override the coding methods, because our superclass's methods are sufficient. This is because we don't want to encode our document, layer, page, and graphic, as these objects will set themselves onto use during their decoding. This helps prevent the document archive from getting cluttered.

}
