/*
DrawStrokeDash.m
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

import AJRInterface

public let DrawStrokeDashesKey = "strokeDashes";

public extension AJRUserDefaultsKey {
    static var strokeDashes : AJRUserDefaultsKey<[String]> {
        return AJRUserDefaultsKey<[String]>.key(named: DrawStrokeDashesKey, defaultValue: [""])
    }
}

@objcMembers
open class DrawStrokeDash : NSObject, AJREquatable, AJRXMLCoding, AJRUserDefaultProvider {
    
    var dash : [CGFloat]? = nil
    lazy var image : NSImage? = {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0.0, alpha: 2.0 / 3.0)
        shadow.shadowBlurRadius = 3.0
        shadow.shadowOffset = NSSize(width: 0.0, height: -1.5)
            
        let _image = AJRImage.image(size: CGSize(width: 90.0, height: 9.0), scales: [1.0, 2.0], flipped: false, colorSpace: nil, commands: { scale in
            shadow.set()
            NSColor.clear.set()
            NSRect(x: 0.0, y: 0.0, width: 90.0, height: 90.0).fill()
            NSColor.black.set()
            let transform = NSAffineTransform()
            transform.scale(by: 3.0)
            transform.concat()
            let path = AJRBezierPath()
            path.setLineDash(self.dash, phase: self.offset)
            path.moveTo(x: 1.0, y: 1.5);
            path.relativeLineTo(x: 26.0, y: 0.0)
            self.add(to: path)
            path.stroke()
        })
        image?.isTemplate = true
        
        return _image;
    }()
    var count : Int { return dash?.count ?? 0 }
    var offset : CGFloat = 0.0
    
    //+ (NSArray *)defaultDashes {
    //    static NSMutableArray *dashes;
    //    static dispatch_once_t onceToken;
    //
    //    dispatch_once(&onceToken, ^{
    //        NSArray		*prefDashes;
    //        NSInteger	x;
    //
    //        dashes = [[NSMutableArray alloc] init];
    //
    //        prefDashes = [[NSUserDefaults standardUserDefaults] arrayForKey:DrawStrokeDashesKey];
    //        for (x = 0; x < (const NSInteger)[prefDashes count]; x++) {
    //            [dashes addObject:[[DrawStrokeDash alloc] initWithString:[prefDashes objectAtIndex:x]]];
    //        }
    //    });
    //
    //    return dashes;
    //}
    
    // MARK: - Creation
    
    required public override init() {
        super.init()
    }
    
    public init(string: String) {
        super.init()
        self.stringValue = string
    }
    
    // MARK: - Utilities
    
    public static var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.positiveFormat = "###0.######"
        formatter.negativeFormat = "###0.######"
        return formatter;
    }()
    
    open func add(to path: AJRBezierPath) {
        if let dash {
            let width = path.lineWidth
            path.setLineDash(dash.map { $0 * width }, phase: offset * width)
        } else {
            path.setLineDash(nil, count: 0, phase: 0)
        }
    }
    
    open var stringValue : String? {
        set(string) {
            dash = nil
            image = nil
            
            if let string {
                var offset = string.startIndex
                if let index = string.firstIndex(of: ":") {
                    offset = string.index(index, offsetBy: 1)
                    if let offset = Double(string.prefix(upTo: index)) {
                        self.offset = offset
                    }
                }
                dash = Array<CGFloat>()
                let scanner = Scanner(string: String(string.suffix(from: offset)))
                while let value = scanner.scanDouble() {
                    dash?.append(value)
                }
            }
        }
        get {
            var string = ""

            if let dash {
                let formatter = type(of:self).formatter
                
                if offset > 0, let offsetString = formatter.string(for: offset) {
                    string += "\(offsetString): "
                }
                for (x, value) in dash.enumerated() {
                    if x > 0 {
                        string.append(" ")
                    }
                    if let converted = formatter.string(for: value) {
                        // Generally expect this to always work, so don't really handle the error case.
                        string += converted
                    }
                }
            }
            
            return string
        }
    }
        
    // MARK: - NSCopying
    
    open func copy(with zone: NSZone?) -> Any {
        let new = DrawStrokeDash()
        
        new.dash = dash
        new.offset = offset
        new.image = image?.copy() as? NSImage
        
        return new;
    }
    
    // MARK: - AJRXMLCoding
    
    open func decode(with coder: AJRXMLCoder) {
        coder.decodeString(forKey: "pattern") { string in
            self.stringValue = string
        }
        coder.decodeDouble(forKey: "offset") { value in
            self.offset = CGFloat(value)
        }
    }
    
    open func encode(with coder: AJRXMLCoder) {
        if let stringValue {
            coder.encode(stringValue, forKey: "pattern")
        }
        coder.encode(offset, forKey: "offset")
    }
    
    open class override var ajr_nameForXMLArchiving: String {
        return "dash"
    }
    
    // MARK: - AJREquatable
    
    open func isEqual(toStrokeDash other: DrawStrokeDash) -> Bool {
        return (AJRAnyEquals(dash, other.dash)
                && AJRAnyEquals(offset, other.offset))
    }
    
    open override func isEqual(to object: Any?) -> Bool {
        if let object = object as? DrawStrokeDash {
            return isEqual(toStrokeDash: object)
        }
        return false
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        return isEqual(to: object)
    }

    // MARK: - NSObject
    
    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(description)
        hasher.combine(offset)
        return hasher.finalize()
    }
    
    open override var description: String {
        return stringValue ?? "<empty>"
    }

    // MARK: - AJRUserDefaultsProvider
    
    public static func userDefault(forKey key: String, from userDefaults: UserDefaults) -> DrawStrokeDash? {
        if let string = userDefaults.string(forKey: key) {
            return DrawStrokeDash(string: string)
        }
        return nil
    }
    
    public static func setUserDefault(_ value: DrawStrokeDash?, forKey key: String, into userDefaults: UserDefaults) {
        if let value {
            userDefaults.set(value.stringValue, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }

}
