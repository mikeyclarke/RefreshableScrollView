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
    private var didBeginScrollNearToTop: Bool = true
    private var lastDeactivationTime: Date?
    private var isControlLocked: Bool = false

    private var distanceFromSafeArea: CGFloat? {
        guard let scrollView = self.enclosingScrollView else {
            return nil
        }

        return self.previousScrollViewOffset.y + scrollView.contentInsets.top
    }

    var height: CGFloat {
        return self.frame.size.height
    }

    public var masksToSafeArea: Bool = false

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

    public func beginRefreshing(revealingControl lockControl: Bool = true) {
        guard self.isEnabled, !self.state.isActivated else {
            return
        }

        self.updateClippingMask()
        self.state = .activated

        if lockControl {
            self.lockControlInView()
        }
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
        if let scrollView = self.enclosingScrollView {
            let diff = scrollView.contentInsets.top - scrollView.safeAreaInsets.top
            var adjustedScrollOrigin = scrollView.contentView.bounds.origin
            adjustedScrollOrigin.y -= diff

            scrollView.contentInsets = scrollView.safeAreaInsets
            scrollView.contentView.setBoundsOrigin(adjustedScrollOrigin)
            scrollView.reflectScrolledClipView(scrollView.contentView)

            self.previousScrollViewOffset.y = 0
        }

        self.isControlLocked = false
        self.state = .idle
        self.lastDeactivationTime = Date.now
    }

    private func lockControlInView() {
        if let scrollView = self.enclosingScrollView {
            scrollView.contentInsets.top = scrollView.safeAreaInsets.top + self.height
            self.isControlLocked = true
        }
    }

    private func lockControlIfFullyRevealed() {
        guard let distanceFromSafeArea = self.distanceFromSafeArea else {
            return
        }

        if distanceFromSafeArea < -self.height {
            self.lockControlInView()
        }
    }

    private func updateStateAfterScroll() {
        guard let distanceFromSafeArea = self.distanceFromSafeArea else {
            return
        }

        switch distanceFromSafeArea {
        case ..<(-self.height) where self.canRefresh:
            self.state = .activated
            self.lockControlInView()
            if let action = self.action, let target = self.target {
                self.sendAction(action, to: target)
            }
        case ..<0:
            self.state = .triggering(progress: (-distanceFromSafeArea / self.height))
        default:
            self.state = .idle
        }
    }

    private func updateClippingMask() {
        guard let scrollView = self.enclosingScrollView else {
            return
        }

        guard self.masksToSafeArea else {
            self.layer?.mask = nil
            return
        }

        self.wantsLayer = true

        let mask = self.layer?.mask ?? CALayer()
        mask.backgroundColor = NSColor.black.cgColor
        self.layer?.mask = mask

        let refreshControlFrameInScrollView = self.convert(self.bounds, to: scrollView)

        let visibleTop = max(refreshControlFrameInScrollView.minY, scrollView.safeAreaInsets.top)
        let visibleHeight = max(0, refreshControlFrameInScrollView.maxY - visibleTop)
        let maskY = visibleTop - refreshControlFrameInScrollView.minY

        mask.frame = CGRect(
            x: 0,
            y: maskY,
            width: self.bounds.width,
            height: visibleHeight
        )
    }

    @objc private func didStartScrolling(_ notification: Notification) {
        guard let scrollView = self.enclosingScrollView else {
            return
        }

        self.updateClippingMask()

        let offset = scrollView.documentVisibleRect.minY - -scrollView.contentInsets.top
        self.didBeginScrollNearToTop = offset < (scrollView.contentSize.height / 3)
    }

    @objc private func clipViewBoundsChanged(_ notification: Notification) {
        self.updateClippingMask()

        guard let scrollView = self.enclosingScrollView else {
            return
        }

        switch self.state {
        case .deactivating:
            return
        case .activated:
            guard !self.isControlLocked else {
                return
            }
            self.lockControlIfFullyRevealed()
        case .triggering, .idle:
            self.updateStateAfterScroll()
        }

        self.previousScrollViewOffset.y = scrollView.documentVisibleRect.minY
    }
}
