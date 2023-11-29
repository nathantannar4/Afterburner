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
public struct NavigationContainer<
    Content: View,
    NavigationBar: View
>: View {
    @StateOrBinding var path: Int
    var configuration: NavigationContainerConfiguration
    var content: Content
    var navigationBar: NavigationBar

    public init(
        path: Binding<Int>,
        configuration: NavigationContainerConfiguration = .automatic,
        @ViewBuilder content: () -> Content,
        @ViewBuilder navigationBar: () -> NavigationBar
    ) {
        self._path = .init(path)
        self.configuration = configuration
        self.content = content()
        self.navigationBar = navigationBar()
    }

    public init(
        configuration: NavigationContainerConfiguration = .automatic,
        @ViewBuilder content: () -> Content,
        @ViewBuilder navigationBar: () -> NavigationBar
    ) {
        self._path = .init(0)
        self.configuration = configuration
        self.content = content()
        self.navigationBar = navigationBar()
    }

    public var body: some View {
        ControllerContainer { proxy in
            NavigationContainerBody(
                path: $path,
                configuration: configuration,
                content: content,
                proxy: proxy,
                navigationBar: navigationBar
            )
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension NavigationContainer where NavigationBar == EmptyView {

    public init(
        path: Binding<Int>,
        configuration: NavigationContainerConfiguration = .automatic,
        @ViewBuilder content: () -> Content
    ) {
        self.init(path: path, configuration: configuration, content: content, navigationBar: { EmptyView() })
    }

    public init(
        configuration: NavigationContainerConfiguration = .automatic,
        @ViewBuilder content: () -> Content
    ) {
        self.init(configuration: configuration, content: content, navigationBar: { EmptyView() })
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@frozen
public struct NavigationContainerConfiguration {
    public var standardAppearance: UINavigationBarAppearance?
    public var scrollEdgeAppearance: UINavigationBarAppearance?
    public var compactAppearance: UINavigationBarAppearance?
    public var compactScrollEdgeAppearance: UINavigationBarAppearance?

    public init(
        standardAppearance: UINavigationBarAppearance? = nil,
        scrollEdgeAppearance: UINavigationBarAppearance? = nil,
        compactAppearance: UINavigationBarAppearance? = nil,
        compactScrollEdgeAppearance: UINavigationBarAppearance? = nil
    ) {
        self.standardAppearance = standardAppearance
        self.scrollEdgeAppearance = scrollEdgeAppearance
        self.compactAppearance = compactAppearance
        self.compactScrollEdgeAppearance = compactScrollEdgeAppearance
    }

    public static let automatic = NavigationContainerConfiguration()

    public static let transparent: NavigationContainerConfiguration = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        return NavigationContainerConfiguration(
            standardAppearance: appearance,
            scrollEdgeAppearance: appearance,
            compactAppearance: appearance,
            compactScrollEdgeAppearance: appearance
        )
    }()
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct NavigationContainerBody<
    Content: View,
    NavigationBar: View
>: UIViewControllerRepresentable {

    var path: Binding<Int>
    var configuration: NavigationContainerConfiguration
    var content: Content
    var proxy: ControllerContainerProxy
    var navigationBar: NavigationBar

    func makeUIViewController(
        context: Context
    ) -> NavigationContainerController<Content, NavigationBar> {
        let uiViewController = NavigationContainerController<Content, NavigationBar>(content: content)
        return uiViewController
    }

    func updateUIViewController(
        _ uiViewController: NavigationContainerController<Content, NavigationBar>,
        context: Context
    ) {
        uiViewController.update(
            content,
            path: path,
            configuration: configuration,
            proxy: proxy,
            navigationBar: navigationBar,
            environment: context.environment,
            transaction: context.transaction
        )
    }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private class NavigationContainerController<
    Content: View,
    NavigationBar: View
>: UINavigationController, UINavigationControllerDelegate {

    private var path: Binding<Int> = .constant(0)

    private var safeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            if oldValue != safeAreaInsets {
                additionalSafeAreaInsets = getAdditionalSafeAreaInsets(for: self, safeAreaInsets: safeAreaInsets)
            }
        }
    }

    override var childForStatusBarStyle: UIViewController? {
        topViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        topViewController
    }

    fileprivate let host: HostingController<Content>
    private var navigationBarHostingView: HostingView<NavigationBar>?

    init(content: Content) {
        self.host = HostingController(content: content)
        super.init(rootViewController: host)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
        delegate = self

        if NavigationBar.self == EmptyView.self {
            navigationBar.isHidden = true
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let navigationBarHostingView = navigationBarHostingView,
            let backgroundView = navigationBar.subviews.first
        {
            backgroundView.addSubview(navigationBarHostingView)
            navigationBarHostingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                navigationBarHostingView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
                navigationBarHostingView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
                navigationBarHostingView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
                navigationBarHostingView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
            ])
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
//        navigationBarHostingView?.additionalSafeAreaInsets.top = view.safeAreaInsets.top
    }

    func update(
        _ content: Content,
        path: Binding<Int>,
        configuration: NavigationContainerConfiguration,
        proxy: ControllerContainerProxy,
        navigationBar: NavigationBar,
        environment: EnvironmentValues,
        transaction: Transaction
    ) {
        safeAreaInsets = UIEdgeInsets(
            proxy.safeAreaInsets,
            layoutDirection: environment.layoutDirection
        )

        self.path = path
        let path = path.wrappedValue
        if path < viewControllers.count - 1 {
            withCATransaction {
                let vc = self.viewControllers[path]
                self.popToViewController(vc, animated: transaction.isAnimated)
            }
        }

        configuration.apply(to: self.navigationBar)

        self.host.content = content
        if topViewController != viewControllers.first {
            withCATransaction {
                self.host.render()
            }
        }

        if let navigationBarHostingView = navigationBarHostingView {
            navigationBarHostingView.content = navigationBar
        } else if NavigationBar.self != EmptyView.self {
            let hostingView = HostingView(content: navigationBar)
            hostingView.disablesSafeArea = true
//            hostingView.additionalSafeAreaInsets.top = view.safeAreaInsets.top
            navigationBarHostingView = hostingView
        }
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        additionalSafeAreaInsets = getAdditionalSafeAreaInsets(for: self, safeAreaInsets: safeAreaInsets)
    }

    override func pushViewController(
        _ viewController: UIViewController,
        animated: Bool
    ) {
        if !viewControllers.isEmpty {
            viewController.view.backgroundColor = view.backgroundColor ?? .systemBackground
        } else {
            viewController.view.backgroundColor = nil
        }
        _ = viewController.view.intrinsicContentSize
        super.pushViewController(viewController, animated: animated)
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        guard let index = viewControllers.firstIndex(of: viewController) else {
            return
        }
        path.wrappedValue = index
    }
}

@frozen
@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct NavigationBarModifier: ViewModifier {

    @inlinable
    public init() { }

    public func body(content: Content) -> some View {
        content
            .font(.headline)
            .lineLimit(1)
            .labelStyle(NavigationBarLabelStyle())
            .buttonStyle(NavigationBarButtonStyle())
    }

    private struct NavigationBarButtonStyle: PrimitiveButtonStyle {
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
            func body(content: Content) -> some View {
                content
                    .font(.body)
                    .frame(minWidth: 32, minHeight: 32)
                    .contentShape(RoundedRectangle(cornerRadius: 5))
            }
        }
    }

    private struct NavigationBarLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.icon
                .font(.body)
        }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension NavigationContainerConfiguration {
    func apply(to navigationBar: UINavigationBar) {
        if let appearance = standardAppearance {
            navigationBar.standardAppearance = appearance
        } else {
            navigationBar.standardAppearance.configureWithDefaultBackground()
        }
        navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        navigationBar.compactAppearance = compactAppearance
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = compactScrollEdgeAppearance
        }
    }
}

// MARK: - Previews

struct TestPref: PreferenceKey {
    static var defaultValue: String = "default"
    static func reduce(value: inout String, nextValue: () -> String) {
        value = nextValue()
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NavigationContainer_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }

    struct Preview: View {
        @State var value = ""
        @State var path = 0

        var body: some View {
            NavigationContainer(path: $path) {
                ScrollView {
                    DestinationLink {
                        Text("Hello, World")
                            .preference(key: TestPref.self, value: "Page 2")
                    } label: {
                        Text("Next")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
                .navigationTitle("Title")
//                .navigationTitle("as")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {

                        } label: {
                            Text("ahas")
                        }
                    }
                }
                .preference(key: TestPref.self, value: "Page 1")
            } navigationBar: {
                ZStack {
                    Color.yellow
                        .opacity(0.3)
                        .ignoresSafeArea()
                }
            }
//            .overlay(Text(value), alignment: .top)
            .overlay(Text(path.description), alignment: .bottom)
            .onPreferenceChange(TestPref.self) { value = $0 }
        }
    }
}

#endif
