import AppKit

open class RefreshableScrollView: NSScrollView {
    private var cachedSafeAreaInsets: NSEdgeInsets?

    private lazy var unsafeAreaLayoutGuide: NSLayoutGuide = {
        let unsafeAreaLayoutGuide = NSLayoutGuide()
        self.contentView.addLayoutGuide(unsafeAreaLayoutGuide)

        NSLayoutConstraint.activate([
            unsafeAreaLayoutGuide.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            unsafeAreaLayoutGuide.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            unsafeAreaLayoutGuide.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            unsafeAreaLayoutGuide.bottomAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.topAnchor),
        ])

        return unsafeAreaLayoutGuide
    }()

    public var refreshControl: RefreshControl? {
        didSet {
            oldValue?.removeFromSuperview()

            guard let refreshControl = self.refreshControl else {
                self.automaticallyAdjustsContentInsets = true
                self.cachedSafeAreaInsets = nil
                return
            }

            self.automaticallyAdjustsContentInsets = false

            refreshControl.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(refreshControl)

            var constraints = [
                refreshControl.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
                refreshControl.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
                refreshControl.heightAnchor.constraint(equalTo: self.unsafeAreaLayoutGuide.heightAnchor),
            ]

            if let documentView = self.documentView {
                constraints.append(refreshControl.bottomAnchor.constraint(equalTo: documentView.topAnchor))
            }

            NSLayoutConstraint.activate(constraints)
        }
    }

    open override func layout() {
        super.layout()

        self.updateContentInsets()
    }

    private func updateContentInsets() {
        guard
            !self.automaticallyAdjustsContentInsets,
            !self.safeAreaInsets.isEqual(to: self.cachedSafeAreaInsets)
        else {
            return
        }

        var adjustedInsets = self.safeAreaInsets
        if let control = self.refreshControl, control.isRefreshing {
            adjustedInsets.top += control.height
        }
        self.contentInsets = adjustedInsets

        self.cachedSafeAreaInsets = self.safeAreaInsets
    }
}

private extension NSEdgeInsets {
    func isEqual(to other: NSEdgeInsets?) -> Bool {
        guard let other else {
            return false
        }

        return
            self.top == other.top &&
            self.left == other.left &&
            self.bottom == other.bottom &&
            self.right == other.right
    }
}
