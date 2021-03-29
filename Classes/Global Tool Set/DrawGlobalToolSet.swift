
import Cocoa

public extension DrawToolSetId {
    static var global: DrawToolSetId {
        return DrawToolSetId("global")
    }
}

@objc open class DrawGlobalToolSet: DrawToolSet {

    public class var identifier : String { return "global" }

}
