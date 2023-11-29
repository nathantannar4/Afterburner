//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Engine
import Turbocharger
import Transmission

open class HostingScrollView<Content: View>: UIScrollView {

    open var axis: Axis.Set {
        didSet {
            if oldValue != axis {
                layoutAxisDidChange()
                setNeedsLayout()
            }
        }
    }

    open var showsIndicators: Bool {
        didSet {
            showsVerticalScrollIndicator = showsIndicators && axis.contains(.vertical)
            showsHorizontalScrollIndicator = showsIndicators && axis.contains(.horizontal)
        }
    }

    open override var isPagingEnabled: Bool {
        didSet {
            layoutAxisDidChange()
        }
    }

    public var content: Content {
        get { host.content }
        set {
            host.content = newValue
            setNeedsLayout()
        }
    }

    open override var alwaysBounceVertical: Bool {
        get { bounces && axis.contains(.vertical) }
        set { }
    }

    open override var alwaysBounceHorizontal: Bool {
        get { bounces && axis.contains(.horizontal) }
        set { }
    }

    open override var intrinsicContentSize: CGSize {
        var size = host.intrinsicContentSize
        if axis.contains(.vertical) {
            size.height = UIView.noIntrinsicMetric
        }
        if axis.contains(.horizontal) {
            size.width = UIView.noIntrinsicMetric
        }
        return size
    }

    private var heightConstraint: NSLayoutConstraint!
    private var widthConstraint: NSLayoutConstraint!
    private let host: HostingView<Content>

    public init(
        axis: Axis.Set = .vertical,
        showsIndicators: Bool = false,
        content: Content
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.host = HostingView(content: content)
        super.init(frame: .zero)

        clipsToBounds = false

        keyboardDismissMode = .interactive

        addSubview(host)
        host.disablesSafeArea = true
        host.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: topAnchor),
            host.bottomAnchor.constraint(equalTo: bottomAnchor),
            host.leadingAnchor.constraint(equalTo:  leadingAnchor),
            host.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        heightConstraint = host.heightAnchor.constraint(
            equalTo: heightAnchor
        )
        widthConstraint = host.widthAnchor.constraint(
            equalTo: widthAnchor
        )

        layoutAxisDidChange()
    }

    public convenience init(
        axis: Axis.Set = .vertical,
        showsIndicators: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.init(axis: axis, showsIndicators: showsIndicators, content: content())
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        var size = host.sizeThatFits(
            CGSize(
                width: axis.contains(.horizontal) ? .infinity : bounds.size.width,
                height: axis.contains(.vertical) ? .infinity : bounds.size.height
            )
        )
        if axis.contains(.vertical) {
            size.width = max(bounds.size.width, size.width)
        }
        if axis.contains(.horizontal) {
            size.height = max(bounds.size.height, size.height)
        }
        contentSize = size
        host.frame.size = size
    }

    private func layoutAxisDidChange() {
        setContentHuggingPriority(
            axis.contains(.horizontal) ? .defaultLow : .fittingSizeLevel,
            for: .horizontal
        )
        setContentCompressionResistancePriority(
            .fittingSizeLevel,
            for: .horizontal
        )
        setContentHuggingPriority(
            axis.contains(.vertical) ? .defaultLow : .fittingSizeLevel,
            for: .vertical
        )
        setContentCompressionResistancePriority(
            axis.contains(.horizontal) ? .defaultHigh : .fittingSizeLevel,
            for: .vertical
        )
        widthConstraint.isActive = axis.contains(.vertical)
        heightConstraint.isActive = axis.contains(.horizontal)
    }
}

public struct HostingScrollViewAdapter<Content: View>: View {
    var axis: Axis.Set
    var showsIndicators: Bool
    var isPagingEnabled: Bool
    var bounces: Bool
    var content: Content

    public init(
        _ axis: Axis.Set = [.vertical],
        showsIndicators: Bool = true,
        isPagingEnabled: Bool = false,
        bounces: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.isPagingEnabled = isPagingEnabled
        self.bounces = bounces
        self.content = content()
    }

    public var body: some View {
        HostingScrollViewAdapterBody(
            axis: axis,
            showsIndicators: showsIndicators,
            isPagingEnabled: isPagingEnabled,
            bounces: bounces,
            content: content
        )
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
enum HostingScrollViewObserversKey: EnvironmentKey {
    static let defaultValue = NSHashTable<UIScrollViewDelegate>(options: .weakMemory, capacity: 1)
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension EnvironmentValues {
    var hostingScrollViewObservers: NSHashTable<UIScrollViewDelegate> {
        get { self[HostingScrollViewObserversKey.self] }
        set { self[HostingScrollViewObserversKey.self] = newValue }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct HostingScrollViewObserver: ViewModifier {
    weak var delegate: UIScrollViewDelegate?

    public init(delegate: UIScrollViewDelegate) {
        self.delegate = delegate
    }

    public func body(content: Content) -> some View {
        content
            .transformEnvironment(\.hostingScrollViewObservers) { value in
                value.add(delegate)
            }
    }
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct HostingScrollViewOffsetReader: ViewModifier {
    private class Coordinator: NSObject, ObservableObject, UIScrollViewDelegate {
        var value: Binding<CGPoint>

        init(value:Binding<CGPoint>) {
            self.value = value
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            value.wrappedValue = scrollView.contentOffset
        }
    }

    @Binding var value: CGPoint
    @StateObject private var coordinator: Coordinator

    public init(_ value: Binding<CGPoint>) {
        self._value = value
        self._coordinator = StateObject(wrappedValue: Coordinator(value: value))
    }

    public func body(content: Content) -> some View {
        content
            .modifier(HostingScrollViewObserver(delegate: coordinator))
    }
}

private struct HostingScrollViewAdapterBody<
    Content: View
>: UIViewRepresentable {

    var axis: Axis.Set
    var showsIndicators: Bool
    var isPagingEnabled: Bool
    var bounces: Bool
    var content: Content

    func makeUIView(context: Context) -> HostingScrollView<Content> {
        let uiView = HostingScrollView(content: content)
        uiView.delegate = context.coordinator
        return uiView
    }

    func updateUIView(
        _ uiView: HostingScrollView<Content>,
        context: Context
    ) {
        uiView.axis = axis
        uiView.showsIndicators = showsIndicators
        uiView.isPagingEnabled = isPagingEnabled
        uiView.bounces = bounces
        uiView.content = content
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            context.coordinator.observers = context.environment.hostingScrollViewObservers
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, ObservableObject, UIScrollViewDelegate {
        weak var observers: NSHashTable<UIScrollViewDelegate>?

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            observers?.allObjects.forEach { $0.scrollViewDidScroll?(scrollView) }
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            observers?.allObjects.forEach { $0.scrollViewWillBeginDragging?(scrollView) }
        }

        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            observers?.allObjects.forEach { $0.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset) }
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
            observers?.allObjects.forEach { $0.scrollViewDidEndDragging?(scrollView, willDecelerate: willDecelerate) }
        }

        func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
            observers?.allObjects.allSatisfy { $0.scrollViewShouldScrollToTop?(scrollView) ?? true } ?? true
        }

        func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
            observers?.allObjects.forEach { $0.scrollViewDidScrollToTop?(scrollView) }
        }

        func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
            observers?.allObjects.forEach { $0.scrollViewWillBeginDecelerating?(scrollView) }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            observers?.allObjects.forEach { $0.scrollViewDidEndDecelerating?(scrollView) }
        }

        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            observers?.allObjects.forEach { $0.scrollViewWillBeginZooming?(scrollView, with: view) }
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            observers?.allObjects.forEach { $0.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale) }
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            observers?.allObjects.forEach { $0.scrollViewDidZoom?(scrollView) }
        }

        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            observers?.allObjects.forEach { $0.scrollViewDidEndScrollingAnimation?(scrollView) }
        }

        func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
            observers?.allObjects.forEach { $0.scrollViewDidChangeAdjustedContentInset?(scrollView) }
        }
    }
}

// MARK: - Previews

struct HostingScrollViewAdapter_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            let inset: CGFloat = 12
            HostingScrollViewAdapter(
                .horizontal,
                showsIndicators: false,
                isPagingEnabled: true
            ) {
                HStack(spacing: 0) {
                    Group {
                        Color.red
                        Color.blue
                        Color.yellow
                    }
                    .padding(.horizontal, inset / 2)
                    .aspectRatio(2, contentMode: .fit)
                }
            }
            .aspectRatio(2, contentMode: .fit)
            .padding(.horizontal, inset)
        }

        GeometryReader { proxy in
            let inset: CGFloat = 12
            ScrollView {
                HostingScrollViewAdapter(
                    .horizontal,
                    showsIndicators: false,
                    isPagingEnabled: true
                ) {
                    HStack(spacing: 0) {
                        ForEach(0...10, id: \.self) { index in
                            Cell(index: index)
                                .padding(.horizontal, inset / 2)
                        }
                        .frame(width: proxy.size.width - 2 * inset)
                    }
                }
                .padding(.horizontal, inset)
            }
        }

        VStack {
            ScrollView(.horizontal) {
                Text("Hello, World")
                    .background(Color.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.yellow)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)

            HostingScrollViewAdapter(.horizontal) {
                Text("Hello, World")
                    .background(Color.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.yellow)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)
        }

        HStack {
            ScrollView(.vertical) {
                VStack {
                    Text("Hello, World")
                        .background(Color.red)
                        .padding()
                        .background(Color.yellow)

                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(1...100, id: \.self) { i in
                                Text("Row \(i)")
                                    .background(Color.red)
                            }
                        }
                    }
                    .background(Color.yellow)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)

            HostingScrollViewAdapter(.vertical) {
                VStack {
                    Text("Hello, World")
                        .background(Color.red)
                        .padding()
                        .background(Color.yellow)

                    HostingScrollViewAdapter(.horizontal) {
                        HStack {
                            ForEach(1...100, id: \.self) { i in
                                Text("Row \(i)")
                                    .background(Color.red)
                            }
                        }
                    }
                    .background(Color.yellow)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)
        }

        HStack {
            ScrollView(.vertical) {
                Text("Hello, World")
                    .background(Color.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.yellow)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)

            HostingScrollViewAdapter(.vertical) {
                Text("Hello, World")
                    .background(Color.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.yellow)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)
        }

        HStack {
            let children = ForEach(1...100, id: \.self) { i in
                Text("Row \(i)")
            }

            ScrollView {
                VStack {
                    children
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)

            HostingScrollViewAdapter {
                VStack {
                    children
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)
        }
    }

    struct Cell: View {
        var index: Int
        var body: some View {
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.3))

                Rectangle()
                    .stroke(Color.black)

                Text(index.description)
            }
            .frame(height: 300)
        }
    }
}

#endif
