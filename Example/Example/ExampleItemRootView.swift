import Cocoa

class ExampleItemRootView: NSView {
    override var wantsUpdateLayer: Bool {
        return true
    }

    @Invalidating(.display)
    var backgroundColor: NSColor? = nil

    override init(frame: NSRect) {
        super.init(frame: frame)

        self.wantsLayer = true
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not implemeneted")
    }

    override func updateLayer() {
        if let backgroundColor = self.backgroundColor {
            self.layer?.backgroundColor = backgroundColor.cgColor
        }
    }
}
