
import AJRFoundation
import AJRInterfaceFoundation
import AJRInterface

public extension AJRUserDefaultsKey {
    static var selectedInspectorGroup : AJRUserDefaultsKey<String> {
        return AJRUserDefaultsKey<String>.key(named: "selectedInspectorGroup", defaultValue: "document")
    }
}

@objcMembers
open class DrawInspectorGroupsController : NSViewController {

    // MARK: - Properties

    /*
     @property (nonatomic,strong) NSView *managedView;
     @property (nonatomic,strong) AJRButtonBar *buttonBar;
     @property (nonatomic,weak) DrawDocument *document;
     @property (nonatomic,readonly,strong) NSString *name;

     #pragma mark - Inspector Controllers

     @property (nonatomic,readonly,strong) NSArray *inspectorControllers;
*/
    @IBOutlet open var managedView : NSView!
    @IBOutlet open var buttonBar : AJRButtonBar!
    open var groups  = [DrawInspectorGroup]()
    open var groupsByID = [String:DrawInspectorGroup]()
    open var selectedGroup : DrawInspectorGroup?

    // MARK: - Creation

    @objc public init() {
        super.init(nibName: "DrawInspectorGroupsController", bundle: Bundle(for: Self.self))
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Groups

    open func inspectorGroup(for id: String) -> DrawInspectorGroup? {
        return groupsByID[id]
    }

    open func indexOfGroup(for id: String) -> Int? {
        return groups.firstIndex { (group) -> Bool in
            return group.identifier == id
        }
    }

    // MARK: - Selection Change

    open func update() -> Void {
        // We shouldn't need to do this. We will need to update the selected objects, though.
//        for group in DrawInspectorGroup.groups {
//            group.viewController.update()
//        }
    }

    open func matchingObjects(in group: DrawInspectorGroup, from objects: [NSObject]) -> [NSObject] {
        var matchingObjects = [NSObject]()
        for object in objects {
            if group.inspectedClasses.contains(where: { (possible) -> Bool in
                return object.isKind(of: possible)
            }) {
                matchingObjects.append(object)
            }
        }
        return matchingObjects
    }

    open func push(_ objects: [NSObject], for identifier: AJRInspectorContentIdentifier) -> Void {
        for group in groups {
            let matchingObjects = self.matchingObjects(in: group, from: objects)
            if matchingObjects.count > 0 {
                group.viewController.push(content: matchingObjects, for: identifier)
            }
        }
    }

    open func pop(_ objects: [NSObject], for identifier: AJRInspectorContentIdentifier) -> Void {
        for group in groups {
            let matchingObjects = self.matchingObjects(in: group, from: objects)
            if matchingObjects.count > 0 {
                group.viewController.pop(content: matchingObjects, for: identifier)
            }
        }
    }

    // MARK: - NSViewController

    open override func viewDidLoad() {
        super.viewDidLoad()

        groups = DrawInspectorGroup.createGroups()
        for group in groups {
            groupsByID[group.identifier] = group
        }
        buttonBar.numberOfButtons = groups.count
        buttonBar.spacing = 8.0
        buttonBar.alignment = .center
        buttonBar.trackingMode = .selectOne
        for (index, group) in groups.enumerated() {
            buttonBar.setImage(group.icon, for: index)
            buttonBar.setTarget(self, for: index)
            buttonBar.setAction(#selector(selectInspectorGroup(_:)), for: index)
        }

        if let selectedGroupIndex = indexOfGroup(for: UserDefaults[.selectedInspectorGroup]!) {
            selectInspectorGroup(at: selectedGroupIndex)
        } else {
            selectInspectorGroup(at: 0)
        }
    }

    open override func loadView() {
        Bundle(for: DrawInspectorGroupsController.self).loadNibNamed("DrawInspectorGroupsController", owner: self, topLevelObjects: nil)
    }

    open func selectInspectorGroup(at index: Int) -> Void {
        AJRLog.info("selected: \(index)")
        buttonBar.setSelected(true, for: index)
        UserDefaults[.selectedInspectorGroup] = groups[index].identifier

        if let selectedGroup = selectedGroup {
            let viewController = selectedGroup.viewController
            viewController.view.removeFromSuperview()
        }

        selectedGroup = groups[index]
        let viewController = selectedGroup!.viewController
        let view = viewController.view
        view.frame = managedView.bounds
        managedView.addSubview(view)
        managedView.addConstraints([
            managedView.topAnchor.constraint(equalTo: view.topAnchor),
            managedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: managedView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: managedView.trailingAnchor),
        ])
    }

    @IBAction open func selectInspectorGroup(_ sender: Any?) -> Void {
        selectInspectorGroup(at: buttonBar.selectedButton)
    }

//- (void)loadView {
//    NSView	*view = [[NSView alloc] initWithFrame:(NSRect){NSZeroPoint, {100.0, 100.0}}];
//
//    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
//
//    _buttonBar = [[AJRButtonBar alloc] initWithFrame:(NSRect){NSZeroPoint, {100.0, 26.0}}];
//    [_buttonBar setTranslatesAutoresizingMaskIntoConstraints:NO];
//    [view addSubview:_buttonBar];
//
//    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_buttonBar]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_buttonBar)]];
//    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_buttonBar(==26)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_buttonBar)]];
//
//    [self setView:view];
//}

}
