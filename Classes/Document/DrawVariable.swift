/*
 DrawVariable.swift
 Draw

 Copyright © 2022, AJ Raftis and Draw authors
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
        super.init(name: AJRVariable.UnsetPlaceholderName, type: AJRVariableType())
    }

    public init(name: String, type: AJRVariableType, value: Any?, document: DrawDocument, page: DrawPage?, layer: DrawLayer?, graphic: DrawGraphic?) {
        self.document = document
        self.layer = layer
        self.page = page
        self.graphic = graphic
        super.init(name: name, type: type, value: value)
    }

    public convenience init(name: String, type: AJRVariableType, value: Any?, document: DrawDocument) {
        self.init(name: name, type: type, value: value, document: document, page: nil, layer: nil, graphic: nil)
    }

    public convenience init(name: String, type: AJRVariableType, value: Any?, document: DrawDocument, page: DrawPage?) {
        self.init(name: name, type: type, value: value, document: document, page: page, layer: nil, graphic: nil)
    }

    public convenience init(name: String, type: AJRVariableType, value: Any?, document: DrawDocument, page: DrawPage?, layer: DrawLayer?) {
        self.init(name: name, type: type, value: value, document: document, page: page, layer: layer, graphic: nil)
    }

    // NSCoding

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) should never be called on \(type(of:self))")
    }

    // MARK: - AJREquatable

    open override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? DrawVariable {
            return (super.isEqual(object)
                    && document === object.document
                    && layer == object.layer
                    && page == object.page
                    && graphic == object.graphic)
        }
        return false
    }

    // MARK: - AJRXMLCoding

    // We don't actually override the coding methods, because our superclass's methods are sufficient. This is because we don't want to encode our document, layer, page, and graphic, as these objects will set themselves onto use during their decoding. This helps prevent the document archive from getting cluttered.
    
    open class override var ajr_nameForXMLArchiving: String {
        return "drawVariable"
    }
    
    // MARK: - CustomStringConversion
    
    open override var description: String {
        // For out purposes, we just return the name, since that's really what we care about.
        return name
    }

}
