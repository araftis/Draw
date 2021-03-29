
import Foundation

public extension DrawDocument {

    /**
     Adds generics for Swift. Makes using this a little nicer.
     */
    func registerUndo<TargetType>(target: TargetType, handler: @escaping (TargetType) -> Void) where TargetType : AnyObject {
        self.registerUndo(withTarget: target) { (target) in
            handler(target as! TargetType)
        }
    }

}
