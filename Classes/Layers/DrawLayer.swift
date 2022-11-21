/*
 DrawLayer.m
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

import AJRInterface

@objcMembers
open class DrawLayer : NSObject, AJRXMLCoding {

    // MARK: - Properties

    open weak var document : DrawDocument? {
        didSet {
            for variable in variableStore {
                if let variable = variable as? DrawVariable {
                    variable.document = document
                    variable.layer = self
                }
            }
        }
    }
    open var name = "" {
        willSet {
            let captured = self.name
            document?.registerUndo(target: self, handler: { target in
                target.name = captured
            })
        }
        didSet {
            document?.noteLayersChanged()
        }
    }
    open var locked = false {
        willSet {
            let captured = self.locked
            document?.registerUndo(target: self, handler: { target in
                target.locked = captured
            })
        }
        didSet {
            document?.pagesNeedDisplay = true
        }
    }
    open var visible = true {
        willSet {
            let captured = self.visible
            document?.registerUndo(target: self, handler: { target in
                target.locked = captured
            })
        }
        didSet {
            document?.pagesNeedDisplay = true
        }
    }
    open var printable = true {
        willSet {
            let captured = self.printable
            document?.registerUndo(target: self, handler: { target in
                target.locked = captured
            })
        }
        didSet {
            document?.pagesNeedDisplay = true
        }
    }
    open var variableStore = AJRStore()

    // MARK: - Creation

    required public override init() {
        // Only used by archiving
        super.init()
    }

    @objc(initWithName:document:)
    public init(name: String, document: DrawDocument) {
        // Set should be done before setDrawView, since once we do that we'll have an undo manager.
        self.name = name
        self.document = document

        super.init()
    }

    // MARK: - Variables

    // TODO: Currently needed for Obj-C compatibility, but the next method is preferred.
    open func addVariablesTo(_ variables : NSMutableArray) {
        for name in variableStore.orderedNames {
            if let variable = variableStore[name] as? AJRVariable {
                if !variables.contains(variable) {
                    variables.add(variable)
                }
            }
        }
    }

    open func addVariables(to variables: inout [AJRVariable]) {
        for name in variableStore.orderedNames {
            if let variable = variableStore[name] as? AJRVariable {
                if !variables.contains(variable) {
                    variables.append(variable)
                }
            }
        }
    }

    open var variables : [AJRVariable] {
        var variables = [AJRVariable]()
        addVariables(to: &variables)
        return variables
    }

    // MARK: - Snapshotting

    // TODO: Might not want these method anymore.

    open var snapshot : [String:Any] {
        return ["name":name, "locked":locked, "visible":visible, "printable":printable]
    }

    @objc(restoreFromSnapshot:)
    open func restore(from snapshot: [String:Any]) {
        name = snapshot["name", "Unnamed"]
        visible = snapshot["visible", true]
        printable = snapshot["printable", true]
        locked = snapshot["locked", false]
    }

    // MARK: - AJRXMLCoding

    open override class var ajr_nameForXMLArchiving: String {
        return "layer"
    }

    public func decode(with coder: AJRXMLCoder) {
        coder.decodeString(forKey: "name") { name in
            self.name = name
        }
        coder.decodeBool(forKey: "locked") { value in
            self.locked = value
        }
        coder.decodeBool(forKey: "visible") { value in
            self.visible = value
        }
        coder.decodeBool(forKey: "printable") { value in
            self.printable = value
        }
        coder.decodeObject(forKey: "variableStore") { store in
            if let store = store as? AJRStore {
                self.variableStore = store
            } else {
                // Created during init, so we don't need to.
            }
        }
    }

    public func encode(with coder: AJRXMLCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(locked, forKey: "locked")
        coder.encode(visible, forKey: "visible")
        coder.encode(printable, forKey: "printable")
        if variableStore.count > 0 {
            // Let's only encode this if it matters, since it usually won't.
            coder.encode(variableStore, forKey: "variableStore")
        }
    }

}
