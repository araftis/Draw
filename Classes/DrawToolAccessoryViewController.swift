
import Cocoa


public extension AJRUserDefaultsKey {
    static var selectedAccessoryView : AJRUserDefaultsKey<String> {
        return AJRUserDefaultsKey<String>.key(named: "selectedAccessoryView")
    }
}

@objcMembers
open class DrawToolAccessoryViewController: DrawViewController {

    // MARK: - Properties

    @IBOutlet open var accessorySelector : NSSegmentedControl!
    @IBOutlet open var accessoryView : NSView!
    open var accessories = [DrawToolAccessory]()
    open var currentAccessory : DrawToolAccessory?

    // MARK: - Creation

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - NSViewController

    override open func viewDidLoad() {
        // Don't do set up here. It's too early for us, as the document won't yet be set.
        super.viewDidLoad()
    }

    override open func documentDidLoad(_ document: DrawDocument) {
        for toolSet in DrawToolSet.toolSets {
            accessories.append(contentsOf: toolSet.accessories)
        }
        children = accessories

        var indexToSelect = 0
        let selectedAccessory = UserDefaults[.selectedAccessoryView]

        accessorySelector.segmentCount = accessories.count
        for (index, accessory) in accessories.enumerated() {
            if let title = accessory.title {
                accessorySelector.setLabel(title, forSegment: index)
            }
            accessorySelector.setImage(accessory.icon, forSegment: index)
            if let selectedAccessory = selectedAccessory {
                if NSUserInterfaceItemIdentifier(selectedAccessory) == accessory.identifier {
                    indexToSelect = index
                }
            }
        }
        accessorySelector.sizeToFit()
        accessorySelector.setSelected(true, forSegment: indexToSelect)
        self.selectAccessory(accessorySelector)
    }

    // MARK: - Actions

    @IBAction open func selectAccessory(_ sender: Any?) -> Void {
        let index = accessorySelector.selectedSegment
        let accessory = accessories[index]

        UserDefaults[.selectedAccessoryView] = accessory.identifier?.rawValue

        if let currentAccessory = currentAccessory {
            currentAccessory.view.removeFromSuperview()
        }

        currentAccessory = accessory
        if let currentAccessory = currentAccessory {
            accessoryView.translatesAutoresizingMaskIntoConstraints = false
            currentAccessory.view.translatesAutoresizingMaskIntoConstraints = false
            accessoryView.addSubview(currentAccessory.view)
            accessoryView.addConstraints([
                accessoryView.leadingAnchor.constraint(equalTo: currentAccessory.view.leadingAnchor),
                accessoryView.trailingAnchor.constraint(equalTo: currentAccessory.view.trailingAnchor),
                accessoryView.topAnchor.constraint(equalTo: currentAccessory.view.topAnchor),
                accessoryView.bottomAnchor.constraint(equalTo: currentAccessory.view.bottomAnchor),
            ])
        }
    }
    
}
