import AppKit

open class RefreshControl: NSControl {
    private static let maximumActivationInterval: TimeInterval = 1

    public enum State {
        case idle
        case triggering(progress: CGFloat)
        case activated
        case deactivating

        var isIdle: Bool {
            return if case .idle = self { true } else { false }
        }

        var isTriggering: Bool {
            return if case .triggering = self { true } else { false }
        }

        var isActivated: Bool {
            return if case .activated = self { true } else { false }
        }

        var isDeactivating: Bool {
            return if case .deactivating = self { true } else { false }
        }
    }

    private var previousScrollViewOffset: CGPoint = .zero
    private var restorableContentInsets: NSEdgeInsets?
    private var didBeginScrollNearToTop: Bool = true
    private var lastDeactivationTime: Date?

    public var canRefresh: Bool {
        if !self.didBeginScrollNearToTop {
            return false
        }

        guard let lastDeactivationTime = self.lastDeactivationTime else {
            return true
        }

        return Date().timeIntervalSince(lastDeactivationTime) > Self.maximumActivationInterval
    }

    public private(set) var state: State = .idle {
        didSet(previousState) {
            guard let scrollView = self.enclosingScrollView else {
                return
            }

            switch self.state {
            case .activated:
                if !previousState.isActivated {
                    self.restorableContentInsets = scrollView.contentInsets
                    scrollView.contentInsets.top += self.frame.size.height
                    self.stateDidChange(from: previousState, to: self.state)
                }
            case .deactivating:
                if previousState.isActivated {
                    Task {
                        await self.willDeactivate()
                        self.stateDidChange(from: previousState, to: self.state)
                        self.completeDeactivation()
                    }
                }
            default:
                self.stateDidChange(from: previousState, to: self.state)
            }
        }
    }

    public var isRefreshing: Bool {
        return if case .activated = self.state { true } else { false }
    }

    deinit {
        if let scrollView = self.enclosingScrollView {
            self.removeScrollObservers(scrollView)
        }
    }

    public override func viewWillMove(toSuperview newSuperview: NSView?) {
        if let scrollView = self.enclosingScrollView {
            self.removeScrollObservers(scrollView)
        }

        super.viewWillMove(toSuperview: newSuperview)
    }

    public override func viewDidMoveToSuperview() {
        guard let scrollView = self.enclosingScrollView else {
            return
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clipViewBoundsChanged(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didStartScrolling(_:)),
            name: NSScrollView.willStartLiveScrollNotification,
            object: scrollView
        )
    }

    open func willDeactivate() async {}

    open func stateDidChange(from previousState: State, to newState: State) {}

    public func beginRefreshing() {
        guard self.isEnabled, !self.state.isActivated else {
            return
        }

        self.state = .activated
    }

    public func endRefreshing() {
        guard self.isEnabled, self.state.isActivated else {
            return
        }

        self.state = .deactivating
    }

    private func removeScrollObservers(_ scrollView: NSScrollView) {
        NotificationCenter.default.removeObserver(
            self,
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        NotificationCenter.default.removeObserver(
            self,
            name: NSScrollView.willStartLiveScrollNotification,
            object: scrollView
        )
    }

    private func completeDeactivation() {
        if let resetContentInsets = self.restorableContentInsets, let scrollView = self.enclosingScrollView {
            let diff = scrollView.contentInsets.top - resetContentInsets.top
            var adjustedScrollOrigin = scrollView.contentView.bounds.origin
            adjustedScrollOrigin.y -= diff

            scrollView.contentInsets = resetContentInsets
            scrollView.contentView.setBoundsOrigin(adjustedScrollOrigin)
            scrollView.reflectScrolledClipView(scrollView.contentView)

            self.previousScrollViewOffset.y = 0
            self.restorableContentInsets = nil
        }

        self.state = .idle
        self.lastDeactivationTime = Date.now
    }

    @objc private func didStartScrolling(_ notification: Notification) {
        guard let scrollView = self.enclosingScrollView else {
            return
        }

        let offset = scrollView.documentVisibleRect.minY - -scrollView.contentInsets.top
        self.didBeginScrollNearToTop = offset < (scrollView.contentSize.height / 3)
    }

    @objc private func clipViewBoundsChanged(_ notification: Notification) {
        guard
            let scrollView = self.enclosingScrollView,
            !self.state.isActivated,
            !self.state.isDeactivating
        else {
            return
        }

        let refreshViewHeight = self.frame.size.height
        let offset = self.previousScrollViewOffset.y + scrollView.contentInsets.top

        switch offset {
        case ..<(-refreshViewHeight) where self.canRefresh:
            self.state = .activated
            if let action = self.action, let target = self.target {
                self.sendAction(action, to: target)
            }
        case ..<0:
            self.state = .triggering(progress: (-offset / refreshViewHeight))
        default:
            self.state = .idle
        }

        self.previousScrollViewOffset.y = scrollView.documentVisibleRect.minY
    }
}
