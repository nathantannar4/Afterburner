//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import Turbocharger
import Transmission

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct TabContainer<
    Selection: Hashable,
    Content: View,
    TabBar: View
>: View {

    @StateOrBinding var selection: Selection
    var configuration: TabContainerConfiguration
    var content: Content
    var tabBar: TabBar

    public init(
        selection: Binding<Selection>,
        configuration: TabContainerConfiguration = .automatic,
        @ViewBuilder content: () -> Content,
        @ViewBuilder tabBar: () -> TabBar
    ) {
        self._selection = .init(selection)
        self.configuration = configuration
        self.content = content()
        self.tabBar = tabBar()
    }

    public var body: some View {
        VariadicViewAdapter {
            content
        } content: { source in
            ControllerContainer { proxy in
                TabContainerBody(
                    selection: $selection,
                    configuration: configuration,
                    content: source,
                    proxy: proxy,
                    tabBar: tabBar
                )
            }
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension TabContainer where TabBar == EmptyView {

    public init(
        selection: Binding<Selection>,
        @ViewBuilder content: () -> Content
    ) {
        self.init(selection: selection, configuration: .automatic, content: content, tabBar: { EmptyView() })
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension TabContainer where Selection == Int {

    public init(
        configuration: TabContainerConfiguration = .automatic,
        @ViewBuilder content: () -> Content,
        @ViewBuilder tabBar: () -> TabBar
    ) {
        self._selection = .init(0)
        self.configuration = configuration
        self.content = content()
        self.tabBar = tabBar()
    }

    public init(
        @ViewBuilder content: () -> Content
    ) where TabBar == EmptyView {
        self.init(configuration: .automatic, content: content, tabBar: { EmptyView() })
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct TabContainerConfiguration {
    public var standardAppearance: UITabBarAppearance?
    public var scrollEdgeAppearance: UITabBarAppearance?

    public init(
        standardAppearance: UITabBarAppearance? = nil,
        scrollEdgeAppearance: UITabBarAppearance? = nil
    ) {
        self.standardAppearance = standardAppearance
        self.scrollEdgeAppearance = scrollEdgeAppearance
    }

    public static let automatic = TabContainerConfiguration()

    public static let transparent: TabContainerConfiguration = {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        return TabContainerConfiguration(
            standardAppearance: appearance,
            scrollEdgeAppearance: appearance
        )
    }()
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct TabContainerBody<
    Selection: Hashable,
    Content: View,
    TabBar: View
>: UIViewControllerRepresentable {

    var selection: Binding<Selection>
    var configuration: TabContainerConfiguration
    var content: VariadicView<Content>
    var proxy: ControllerContainerProxy
    var tabBar: TabBar

    typealias UIViewControllerType = TabContainerController<Selection, Content, TabBar>

    func makeUIViewController(
        context: Context
    ) -> UIViewControllerType {
        let controller = UIViewControllerType(selection: selection)
        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIViewControllerType,
        context: Context
    ) {
        uiViewController.selection = selection
        uiViewController.update(
            content,
            configuration: configuration,
            proxy: proxy,
            tabBar: tabBar,
            environment: context.environment,
            transaction: context.transaction
        )
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private class TabContainerController<
    Selection: Hashable,
    Content: View,
    TabBar: View
>: UITabBarController, UITabBarControllerDelegate {

    var selection: Binding<Selection>
    private var onSelect: ((Int) -> Selection?)?

    private var safeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            if oldValue != safeAreaInsets {
                additionalSafeAreaInsets = getAdditionalSafeAreaInsets(for: self, safeAreaInsets: safeAreaInsets)
            }
        }
    }

    override var childForStatusBarStyle: UIViewController? {
        viewControllers?[selectedIndex]
    }

    override var childForStatusBarHidden: UIViewController? {
        viewControllers?[selectedIndex]
    }

    private var tabBarHostingView: HostingView<ModifiedContent<TabBar, TabBarModifier>>?

    init(selection: Binding<Selection>) {
        self.selection = selection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        view.backgroundColor = nil

        if TabBar.self == EmptyView.self {
            tabBar.isHidden = true
        }
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        additionalSafeAreaInsets = getAdditionalSafeAreaInsets(for: self, safeAreaInsets: safeAreaInsets)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    func update(
        _ content: VariadicView<Content>,
        configuration: TabContainerConfiguration,
        proxy: ControllerContainerProxy,
        tabBar: TabBar,
        environment: EnvironmentValues,
        transaction: Transaction
    ) {
        safeAreaInsets = UIEdgeInsets(
            proxy.safeAreaInsets,
            layoutDirection: environment.layoutDirection
        )

        configuration.apply(to: self.tabBar)

        var viewControllers = (viewControllers ?? [])
        viewControllers.reserveCapacity(content.children.count)
        let remaining = viewControllers.count - content.children.count
        if remaining > 0 {
            viewControllers.removeLast(remaining)
        }

        typealias UIViewControllerType = HostingController<AnyVariadicView.Subview>
        for (index, child) in content.children.enumerated() {
            if viewControllers.count > index {
                let viewController = viewControllers[index] as! UIViewControllerType
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

        if viewControllers != self.viewControllers {
            setViewControllers(viewControllers, animated: transaction.isAnimated)
        }

        let ids = content.children.map { $0.id(as: Selection.self) ?? $0.tag(as: Selection.self) }
        onSelect = { index in
            ids[index]
        }
        selectedIndex = ids.firstIndex(of: selection.wrappedValue) ?? 0

        if let tabBarHostingView = tabBarHostingView {
            tabBarHostingView.content.content = tabBar
        } else if TabBar.self != EmptyView.self {
            let hostingView = HostingView(content: tabBar.modifier(TabBarModifier()))
            self.tabBar.addSubview(hostingView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: self.tabBar.topAnchor),
                hostingView.leadingAnchor.constraint(equalTo: self.tabBar.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: self.tabBar.trailingAnchor),
                hostingView.bottomAnchor.constraint(equalTo: self.tabBar.bottomAnchor),
            ])
            self.tabBar.accessibilityElements = [hostingView]
            tabBarHostingView = hostingView
        }
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let index = tabBar.items?.firstIndex(of: item) ?? selectedIndex
        if let id = onSelect?(index) {
            selection.wrappedValue = id
        }
    }
}

@frozen
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct TabBarModifier: ViewModifier {

    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        content
            .font(.caption)
            .lineLimit(1)
            .labelStyle(TabBarLabelStyle())
            .buttonStyle(TabBarButtonStyle())
    }

    private struct TabBarButtonStyle: PrimitiveButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            Button {
                configuration.trigger()
            } label: {
                configuration.label
                    .modifier(LabelModifier())
            }
            .hoverEffect(.highlight)
            .accessibilityShowsLargeContentViewerIfAvailable()
        }

        struct LabelModifier: ViewModifier {
            @Environment(\.horizontalSizeClass) var horizontalSizeClass

            func body(content: Content) -> some View {
                let size: CGFloat = horizontalSizeClass == .compact ? 18 : 25
                content
                    .frame(minWidth: size, minHeight: size)
                    .contentShape(RoundedRectangle(cornerRadius: 5))
            }
        }
    }

    private struct TabBarLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(alignment: .center) {
                configuration.icon
                configuration.title
            }
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension TabContainerConfiguration {
    func apply(to tabBar: UITabBar) {
        if let appearance = standardAppearance {
            tabBar.standardAppearance = appearance
        } else {
            tabBar.standardAppearance.configureWithDefaultBackground()
        }
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = scrollEdgeAppearance
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct TabContainer_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWithTag()

        PreviewWithForEach()
    }

    struct PreviewWithTag: View {
        @State var selection = 0

        var body: some View {
            TabContainer(selection: $selection) {
                Color.red.tag(0)
                Color.blue.tag(1)
                Color.yellow.tag(2)
            } tabBar: {
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

    struct PreviewWithForEach: View {
        @State var selection = 0

        var body: some View {
            TabContainer(selection: $selection) {
                ForEach(0...2, id: \.self) { id in
                    Text("\(id)")
                }
            } tabBar: {
                WeightedHStack {
                    ForEach(0...2, id: \.self) { id in
                        Button {
                            withAnimation {
                                selection = id
                            }
                        } label: {
                            Text("\(id)")
                        }
                    }
                }
            }
        }
    }
}

#endif
