//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Turbocharger
import Transmission

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct PageContainer<
    Selection: Hashable,
    Content: View
>: View {
    var axis: Axis
    @StateOrBinding var selection: Selection
    var content: Content

    public init(
        axis: Axis = .horizontal,
        selection: Binding<Selection>,
        @ViewBuilder content: () -> Content
    ) {
        self.axis = axis
        self._selection = .init(selection)
        self.content = content()
    }

    public var body: some View {
        VariadicViewAdapter {
            content
        } content: { source in
            ControllerContainer { proxy in
                PageContainerBody(
                    axis: axis,
                    selection: $selection,
                    content: source,
                    proxy: proxy
                )
                .id(axis)
            }
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PageContainer where Selection == Int {
    public init(
        axis: Axis = .horizontal,
        @ViewBuilder content: () -> Content
    ) {
        self.axis = axis
        self._selection = .init(0)
        self.content = content()
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct PageContainerBody<
    Selection: Hashable,
    Content: View
>: UIViewControllerRepresentable {
    var axis: Axis
    var selection: Binding<Selection>
    var content: VariadicView<Content>
    var proxy: ControllerContainerProxy

    typealias UIViewControllerType = PageContainerController<Selection, Content>

    func makeUIViewController(context: Context)
        -> UIViewControllerType
    {
        let uiViewController = UIViewControllerType(axis: axis, selection: selection)
        return uiViewController
    }

    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {
        uiViewController.selection = selection
        uiViewController.update(
            content,
            proxy: proxy,
            environment: context.environment,
            transaction: context.transaction
        )
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private class PageContainerController<
    Selection: Hashable,
    Content: View
>: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var selection: Binding<Selection>
    private var onSelect: ((Int) -> Selection?)?

    var selectedIndex: Int? {
        guard let viewController = viewControllers?.first,
            let index = pageViewControllers.firstIndex(where: { $0 == viewController })
        else {
            return nil
        }
        return index
    }

    override var preferredContentSize: CGSize {
        get {
            let size = super.preferredContentSize
            if size != .zero {
                return size
            }
            guard let viewController = viewControllers?.first else {
                return .zero
            }
            if viewController.preferredContentSize != .zero {
                return viewController.preferredContentSize
            }
            let preferredContentSize = viewController.view.systemLayoutSizeFitting(
                CGSize(
                    width: navigationOrientation == .horizontal ? view.frame.width : UIView.layoutFittingExpandedSize.width,
                    height: navigationOrientation == .vertical ? view.frame.height : UIView.layoutFittingExpandedSize.height
                )
            )
            return preferredContentSize
        }
        set { super.preferredContentSize = newValue }
    }

    private var safeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            if oldValue != safeAreaInsets {
                additionalSafeAreaInsets = getAdditionalSafeAreaInsets(for: self, safeAreaInsets: safeAreaInsets)
            }
        }
    }

    override var childForStatusBarStyle: UIViewController? {
        viewControllers?.first
    }

    override var childForStatusBarHidden: UIViewController? {
        viewControllers?.first
    }

    typealias UIViewControllerType = HostingController<AnyVariadicView.Subview>
    private var pageViewControllers: [UIViewControllerType] = []

    private var scrollView: UIScrollView {
        view.subviews.compactMap { $0 as? UIScrollView }.first!
    }

    init(axis: Axis, selection: Binding<Selection>) {
        self.selection = selection
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: axis == .vertical ? .vertical : .horizontal,
            options: [:]
        )

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil
        scrollView.backgroundColor = nil

        delegate = self
        dataSource = self
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        additionalSafeAreaInsets = getAdditionalSafeAreaInsets(for: self, safeAreaInsets: safeAreaInsets)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewControllers?.first?.beginAppearanceTransition(true, animated: animated)
    }

    func update(
        _ content: VariadicView<Content>,
        proxy: ControllerContainerProxy,
        environment: EnvironmentValues,
        transaction: Transaction
    ) {
        safeAreaInsets = UIEdgeInsets(
            proxy.safeAreaInsets,
            layoutDirection: environment.layoutDirection
        )

        var viewControllers = pageViewControllers
        viewControllers.reserveCapacity(content.children.count)
        let remaining = viewControllers.count - content.children.count
        if remaining > 0 {
            viewControllers.removeLast(remaining)
        }

        for (index, child) in content.children.enumerated() {
            if viewControllers.count > index {
                let viewController = viewControllers[index]
                if viewController.content.id != child.id {
                    // SwiftUI will otherwise lazily destroy the observable objects
                    let viewController = UIViewControllerType(content: child)
                    viewControllers[index] = viewController
                } else {
                    viewController.content = child
                }
            } else {
                let viewController = UIViewControllerType(content: child)
                viewControllers.append(viewController)
            }
        }

        let ids = content.children.map { $0.id(as: Selection.self) ?? $0.tag(as: Selection.self) }
        onSelect = { index in
            ids[index]
        }
        let selection = ids.firstIndex(of: selection.wrappedValue) ?? 0

        if viewControllers != self.pageViewControllers {
            self.pageViewControllers = viewControllers
            displayViewController(at: selection, animated: transaction.isAnimated)
        } else if !scrollView.isDragging, !scrollView.isDecelerating, let selectedIndex = selectedIndex {
            if selection != selectedIndex {
                displayViewController(at: selection, animated: transaction.isAnimated)
            }
        }
    }

    private func displayViewController(at index: Int, animated: Bool) {
        guard index >= 0, index < pageViewControllers.count else {
            return
        }
        let direction: UIPageViewController.NavigationDirection = index > (selectedIndex ?? -1) ? .forward : .reverse
        let viewController = pageViewControllers[index]
        setViewControllers([viewController], direction: direction, animated: animated)
    }

    // MARK: - UIPageViewControllerDataSource

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        nextViewController(viewController, isAfter: true)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        nextViewController(viewController, isAfter: false)
    }

    private func nextViewController(_ viewController: UIViewController, isAfter: Bool) -> UIViewController? {
        guard var index = pageViewControllers.firstIndex(where: { $0 == viewController }) else {
            return nil
        }
        index += isAfter ? 1 : -1
        guard index >= 0 && index < pageViewControllers.count else {
            return nil
        }
        return pageViewControllers[index]
    }

    // MARK: - UIPageViewControllerDelegate

    func pageViewController(
        _ pageViewController: UIPageViewController,
        willTransitionTo pendingViewControllers: [UIViewController]
    ) {
        guard let toViewController = pendingViewControllers.first else {
            return
        }
        let fromSize = preferredContentSize
        let toSize = {
            if toViewController.preferredContentSize != .zero {
                return toViewController.preferredContentSize
            }
            return toViewController.view.systemLayoutSizeFitting(
                CGSize(
                    width: navigationOrientation == .horizontal ? view.frame.width : UIView.layoutFittingExpandedSize.width,
                    height: navigationOrientation == .vertical ? view.frame.height : UIView.layoutFittingExpandedSize.height
                )
            )
        }()
        preferredContentSize = CGSize(
            width: min(fromSize.width, toSize.width),
            height: min(fromSize.height, toSize.height)
        )
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if completed, let index = selectedIndex, let selection = onSelect?(index) {
            self.selection.wrappedValue = selection
        }
        preferredContentSize = .zero
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PageContainer_Previews: PreviewProvider {
    static var previews: some View {
        Preview()

        PageContainer {
            ForEach(0...2, id: \.self) { index in
                Text("\(index)")
            }
        }
    }

    struct Preview: View {
        @State var selection = 0

        var body: some View {
            VStack {
                PageContainer(selection: $selection) {
                    Color.red.tag(0)
                    Color.blue.tag(1)
                    Color.yellow.tag(2)
                }

                WeightedHStack {
                    ForEach(0...2, id: \.self) { tag in
                        Button {
                            withAnimation {
                                selection = tag
                            }
                        } label: {
                            Text("\(tag)")
                        }
                    }
                }
            }
        }
    }
}

#endif
