import Cocoa
import RefreshableScrollView

class ViewController: NSViewController {
    private static let randomColors: [NSColor] = [
        .systemBlue,
        .systemGreen,
        .systemOrange,
        .systemPurple,
        .systemRed,
        .systemTeal,
        .systemYellow
    ]

    private let collectionView: NSCollectionView

    private var dataSource: [ExampleItem] = [
        ExampleItem(title: "Sample Item 1", subtitle: "Description for item 1", color: .systemBlue),
        ExampleItem(title: "Sample Item 2", subtitle: "Description for item 2", color: .systemGreen),
        ExampleItem(title: "Sample Item 3", subtitle: "Description for item 3", color: .systemOrange),
        ExampleItem(title: "Sample Item 4", subtitle: "Description for item 4", color: .systemPurple),
        ExampleItem(title: "Sample Item 5", subtitle: "Description for item 5", color: .systemRed),
        ExampleItem(title: "Sample Item 6", subtitle: "Description for item 6", color: .systemTeal)
    ]

    init() {
        self.collectionView = NSCollectionView()

        super.init(nibName: nil, bundle: nil)

        self.observeMenuItems()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not implemeneted")
    }

    override func loadView() {
        let scrollView = RefreshableScrollView()
        scrollView.documentView = self.collectionView

        let refreshControl = ProgressIndicatorRefreshControl(target: self, action: #selector(refreshControlInvoked(_:)))
        scrollView.refreshControl = refreshControl

        self.setupCollectionView()

        self.view = scrollView
    }

    override func viewWillLayout() {
        super.viewWillLayout()

        self.collectionView.collectionViewLayout?.invalidateLayout()
    }

    private func setupCollectionView() {
        let layout = NSCollectionViewFlowLayout()

        self.collectionView.collectionViewLayout = layout
        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        self.collectionView.register(
            ExampleCollectionViewItem.self,
            forItemWithIdentifier: ExampleCollectionViewItem.reuseIdentifier
        )
    }

    private func observeMenuItems() {
        guard let viewSubmenu = NSApp.mainMenu?.item(with: .init(rawValue: "view"))?.submenu else {
            return
        }

        if let item = viewSubmenu.item(with: .init(rawValue: "viewRefresh")) {
            item.target = self
            item.action = #selector(didTriggerRefreshMenuItem(_:))
        }

        if let item = viewSubmenu.item(with: .init(rawValue: "viewRefreshNoReveal")) {
            item.target = self
            item.action = #selector(didTriggerRefreshWithoutRevealMenuItem(_:))
        }
    }

    private func prependItem(title: String, subtitle: String, color: NSColor = .systemBlue) {
        let newItem = ExampleItem(title: title, subtitle: subtitle, color: color)
        dataSource.insert(newItem, at: 0)

        let indexPath = IndexPath(item: 0, section: 0)
        collectionView.insertItems(at: Set([indexPath]))
    }

    private func prependRandomItem() {
        let itemNumber = dataSource.count + 1

        self.prependItem(
            title: "Item \(itemNumber)",
            subtitle: "Generated item \(itemNumber)",
            color: Self.randomColors.randomElement() ?? .systemBlue
        )
    }

    private func performRefresh() {
        Task {
            try? await Task.sleep(for: .seconds(2))
            self.prependRandomItem()

            await MainActor.run {
                if let scrollView = self.view as? RefreshableScrollView {
                    scrollView.refreshControl?.endRefreshing()
                }
            }
        }
    }

    @objc private func didTriggerRefreshMenuItem(_ sender: NSMenuItem) {
        guard let scrollView = self.view as? RefreshableScrollView, let control = scrollView.refreshControl else {
            return
        }

        if !control.isRefreshing {
            control.beginRefreshing()
            self.performRefresh()
        }
    }

    @objc private func didTriggerRefreshWithoutRevealMenuItem(_ sender: NSMenuItem) {
        guard let scrollView = self.view as? RefreshableScrollView, let control = scrollView.refreshControl else {
            return
        }

        if !control.isRefreshing {
            control.beginRefreshing(revealingControl: false)
            self.performRefresh()
        }
    }

    @objc private func refreshControlInvoked(_ sender: ProgressIndicatorRefreshControl) {
        self.performRefresh()
    }
}

extension ViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: ExampleCollectionViewItem.reuseIdentifier, for: indexPath)

        if let exampleItem = item as? ExampleCollectionViewItem {
            exampleItem.configure(with: dataSource[indexPath.item])
        }

        return item
    }
}

extension ViewController: NSCollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        guard self.dataSource.indices.contains(indexPath.item) else {
            return .zero
        }

        let item = self.dataSource[indexPath.item]
        let width = self.view.bounds.width
        let height = ExampleCollectionViewItem.height(with: item, availableWidth: width)
        return .init(width: width, height: height)
    }
}

extension ViewController: NSCollectionViewDelegate {}

private extension NSMenu {
    func item(with identifier: NSUserInterfaceItemIdentifier) -> NSMenuItem? {
        return self.items.first(where: { $0.identifier == identifier })
    }
}
