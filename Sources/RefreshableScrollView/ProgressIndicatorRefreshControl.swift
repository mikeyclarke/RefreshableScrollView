import AppKit

public final class ProgressIndicatorRefreshControl: RefreshControl {
    private let indicator: RefreshProgressIndicator

    public override var isEnabled: Bool {
        didSet {
            self.indicator.isHidden = !self.isEnabled
        }
    }

    public override var controlSize: NSControl.ControlSize {
        get {
            return self.indicator.controlSize
        }
        set {
            return self.indicator.controlSize = newValue
        }
    }

    public convenience init(target: AnyObject?, action: Selector?) {
        self.init(frame: .zero)

        self.target = target
        self.action = action
    }

    public override init(frame frameRect: NSRect) {
        self.indicator = RefreshProgressIndicator()

        super.init(frame: frameRect)

        self.indicator.progress = 0
        self.indicator.controlSize = .small
        self.indicator.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(self.indicator)

        NSLayoutConstraint.activate([
            self.indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
        ])
    }

    public override func stateDidChange(from previousState: State, to newState: State) {
        switch newState {
        case .idle:
            self.indicator.progress = 0
        case .triggering(let progress):
            var clampedProgress = progress
            if !self.canRefresh {
                clampedProgress = min(0.5, progress)
            }
            self.indicator.progress = clampedProgress
        case .activated:
            self.indicator.progress = 1
            self.indicator.startAnimation(self)
        case .deactivating:
            self.indicator.stopAnimation(self)
            self.indicator.progress = 0
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
