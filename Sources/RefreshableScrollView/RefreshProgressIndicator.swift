import AppKit

final class RefreshProgressIndicator: NSProgressIndicator {
    override var wantsUpdateLayer: Bool {
        return true
    }

    @Invalidating(.display)
    var progress: Double = 1.0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        self.wantsLayer = true
        self.style = .spinning
        self.isDisplayedWhenStopped = true
        self.isIndeterminate = true

        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.fillColor = NSColor.black.cgColor
        self.layer?.mask = maskLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayer() {
        defer {
            super.updateLayer()
        }

        guard let maskLayer = self.layer?.mask as? CAShapeLayer else {
            return
        }

        maskLayer.frame = self.bounds

        let progressProportion = max(0.0, min(1.0, self.progress))
        let progressValue = progressProportion * 2 * .pi

        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let radius = min(self.bounds.width, self.bounds.height) / 2
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + CGFloat(progressValue)

        let path = NSBezierPath()
        path.move(to: center)
        path.appendArc(
            withCenter: center,
            radius: radius,
            startAngle: startAngle.radiansToDegrees,
            endAngle: endAngle.radiansToDegrees,
            clockwise: false
        )
        path.close()

        maskLayer.path = path.cgPath
    }
}
