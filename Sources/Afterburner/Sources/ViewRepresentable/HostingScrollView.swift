//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Turbocharger
import Transmission

/*
open class HostingScrollView<Content: View>: UIScrollView {

    public var axis: Axis.Set {
        didSet {
            if oldValue != axis {
                layoutAxisDidChange()
                setNeedsLayout()
            }
        }
    }

    public var showsIndicators: Bool {
        didSet {
            showsVerticalScrollIndicator = showsIndicators && axis.contains(.vertical)
            showsHorizontalScrollIndicator = showsIndicators && axis.contains(.horizontal)
        }
    }

    public var content: Content {
        get { host.content }
        set {
            host.content = newValue
            setNeedsLayout()
        }
    }

    public override var alwaysBounceVertical: Bool {
        get { bounces && axis.contains(.vertical) }
        set { }
    }

    public override var alwaysBounceHorizontal: Bool {
        get { bounces && axis.contains(.horizontal) }
        set { }
    }

    public override var intrinsicContentSize: CGSize {
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
            host.trailingAnchor.constraint(equalTo: trailingAnchor),
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
*/

#endif
