import Cocoa

class ExampleCollectionViewItem: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier(String(describing: ExampleCollectionViewItem.self))

    private static let padding = NSDirectionalEdgeInsets.asymmetric(vertical: 16, horizontal: 20)
    private static let titleFont = NSFont.preferredFont(forTextStyle: .title3)
    private static let subtitleFont = NSFont.preferredFont(forTextStyle: .body)

    private let titleLabel: NSTextField
    private let subtitleLabel: NSTextField

    private var typedView: ExampleItemRootView? {
        return self.view as? ExampleItemRootView
    }

    override init(nibName: NSNib.Name?, bundle: Bundle?) {
        self.titleLabel = NSTextField(labelWithString: "")
        self.subtitleLabel = NSTextField(wrappingLabelWithString: "")

        super.init(nibName: nibName, bundle: bundle)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not implemeneted")
    }

    override func loadView() {
        self.view = ExampleItemRootView()

        self.setupViews()
        self.setupConstraints()
    }

    private func setupViews() {
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.font = Self.titleFont

        self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.subtitleLabel.font = Self.subtitleFont
        self.subtitleLabel.textColor = .secondaryLabelColor

        self.view.addSubview(titleLabel)
        self.view.addSubview(subtitleLabel)
    }

    private func setupConstraints() {
        let layoutGuide = NSLayoutGuide()
        self.view.addLayoutGuide(layoutGuide)

        NSLayoutConstraint.activate([
            layoutGuide.topAnchor.constraint(equalTo: self.view.topAnchor, constant: Self.padding.top),
            layoutGuide.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -Self.padding.bottom),
            layoutGuide.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: Self.padding.leading),
            layoutGuide.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -Self.padding.trailing),

            self.titleLabel.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
            self.titleLabel.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            self.titleLabel.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),

            self.subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            self.subtitleLabel.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
            self.subtitleLabel.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
            self.subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: layoutGuide.bottomAnchor),
        ])
    }

    func configure(with item: ExampleItem) {
        self.titleLabel.stringValue = item.title
        self.subtitleLabel.stringValue = item.subtitle
        self.typedView?.backgroundColor = item.color.withAlphaComponent(0.1)
    }

    static func height(with item: ExampleItem, availableWidth: CGFloat) -> CGFloat {
        let availableTextWidth = availableWidth - Self.padding.leading - Self.padding.trailing
        let titleHeight = item.title.height(in: availableTextWidth, with: Self.titleFont)
        let subtitleHeight = item.subtitle.height(in: availableTextWidth, with: Self.subtitleFont, isMultiline: true)

        return
            Self.padding.top +
            Self.padding.bottom +
            titleHeight +
            subtitleHeight
    }
}

private extension NSDirectionalEdgeInsets {
    static func asymmetric(vertical: CGFloat, horizontal: CGFloat) -> NSDirectionalEdgeInsets {
        return .init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }
}

private extension NSString {
    func height(in availableWidth: Double, with font: NSFont, isMultiline: Bool = false) -> CGFloat {
        var options: NSString.DrawingOptions = [.usesFontLeading]
        if isMultiline {
            options.insert(.usesLineFragmentOrigin)
        }
        let rect = self.boundingRect(
            with: NSSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude),
            options: options,
            attributes: [.font: font]
        )
        return rect.height
    }
}
