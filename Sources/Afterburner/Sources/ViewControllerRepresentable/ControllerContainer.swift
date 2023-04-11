//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Combine
import Engine
import Turbocharger
import Transmission

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct ControllerContainerProxy: Equatable {
    public var safeAreaInsets: EdgeInsets
}

@available(iOS 14.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct ControllerContainer<Content: View>: View {
    public typealias Proxy = ControllerContainerProxy

    var content: (Proxy) -> Content

    @State private var safeAreaInsets = EdgeInsets()

    public init(@ViewBuilder _ content: @escaping (Proxy) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(ControllerContainerProxy(safeAreaInsets: safeAreaInsets))
            .ignoresSafeArea(.container)
            .background(
                FB11502077Fix_GeometryReader { proxy in
                    Color.clear
                        .onAppear { safeAreaInsets = proxy.safeAreaInsets }
                        .onChange(of: proxy.safeAreaInsets) { newValue in
                            safeAreaInsets = newValue
                        }
                }
                .hidden()
            )
    }
}

private struct FB11502077Fix_GeometryReaderProxy {
    private var proxy: GeometryProxy
    private var keyboardHeight: CGFloat

    init(proxy: GeometryProxy, keyboardHeight: CGFloat) {
        self.proxy = proxy
        self.keyboardHeight = keyboardHeight
    }

    var size: CGSize {
        var size = proxy.size
        size.height = max(0, size.height - keyboardHeight)
        return size
    }

    var safeAreaInsets: EdgeInsets {
        proxy.safeAreaInsets
    }

    subscript<T>(anchor: Anchor<T>) -> T {
        proxy[anchor]
    }

    func frame(in coordinateSpace: CoordinateSpace) -> CGRect {
        proxy.frame(in: coordinateSpace)
    }
}

// FB11502077: [Regression][iOS 16] GeometryReader does not update to keyboard safe area
// Workaround: Manually monitor the keyboard frame ourselves
private struct FB11502077Fix_GeometryReader<Content: View>: View {

    typealias Proxy = FB11502077Fix_GeometryReaderProxy

    @State var keyboardHeight: CGFloat = 0

    var content: (Proxy) -> Content

    init(@ViewBuilder content: @escaping (Proxy) -> Content) {
        self.content = content
    }

    var body: some View {
        #if targetEnvironment(macCatalyst)
        GeometryReader { proxy in
            content(Proxy(proxy: proxy, keyboardHeight: keyboardHeight))
        }
        #else
        _Body(keyboardHeight: $keyboardHeight, content: content)
        #endif
    }


    struct _Body: VersionedView {
        @Binding var keyboardHeight: CGFloat
        var content: (Proxy) -> Content

        @available(iOS 16.0, *)
        var v4Body: some View {
            GeometryReader { proxy in
                content(
                    Proxy(proxy: proxy, keyboardHeight: keyboardHeight)
                )
                .safeAreaPadding(.bottom, keyboardHeight)
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(keyboardHeight > 0 ? .all : .keyboard, edges: .bottom)
            .onReceive(keyboardPublisher) { notification in
                withAnimation(notification.animation) {
                    keyboardHeight = notification.frame.size.height
                }
            }
        }

        var v1Body: some View {
            GeometryReader { proxy in
                content(Proxy(proxy: proxy, keyboardHeight: keyboardHeight))
            }
        }

        private struct KeyboardNotification {
            var frame: CGRect
            var animation: Animation?

            init(userInfo: [AnyHashable: Any]?) {
                let frame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                let animationCurveRawValue = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue
                let animationDurationValue = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber
                let animationCurve = animationCurveRawValue.flatMap { UIView.AnimationCurve(rawValue: $0) }
                let animationDuration = animationDurationValue.flatMap { TimeInterval(truncating: $0) }
                self.frame = frame ?? .zero
                self.animation = animationCurve?.toSwiftUI(duration: animationDuration ?? 0.35)
            }
        }

        private var keyboardPublisher: AnyPublisher<KeyboardNotification, Never> {
            Publishers.Merge3(
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { notification in
                        KeyboardNotification(userInfo: notification.userInfo)
                    },
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
                    .map { notification in
                        KeyboardNotification(userInfo: notification.userInfo)
                    },
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { notification in
                        KeyboardNotification(userInfo: notification.userInfo)
                    }
            )
            .eraseToAnyPublisher()
        }
    }
}


public func getAdditionalSafeAreaInsets(
    for viewController: UIViewController,
    safeAreaInsets: UIEdgeInsets
) -> UIEdgeInsets {
    guard let base = (viewController.parent?.view.safeAreaInsets ?? viewController.view.window?.safeAreaInsets)
    else {
        return .zero
    }
    var insets = safeAreaInsets
    insets.top = max(0, insets.top - base.top)
    insets.left = max(0, insets.left - base.left)
    insets.bottom = max(0, insets.bottom - base.bottom)
    insets.right = max(0, insets.right - base.right)
    return insets
}

#endif
