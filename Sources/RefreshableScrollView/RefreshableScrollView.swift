import AppKit

open class RefreshableScrollView: NSScrollView {
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
                return
            }

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
}
