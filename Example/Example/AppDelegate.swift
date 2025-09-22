import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var viewController: ViewController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 600),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)

        window.center()
        window.title = "Refreshable Scroll View Example"
        window.toolbar = NSToolbar()
        window.toolbar?.displayMode = .iconOnly

        if #available(macOS 15.0, *) {
            window.toolbar?.allowsDisplayModeCustomization = false
        }

        let rootController = ViewController()
        window.contentView = rootController.view

        window.makeKeyAndOrderFront(nil)

        self.window = window
        self.viewController = rootController
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
