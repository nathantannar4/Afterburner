//
// Copyright (c) Nathan Tannar
//

#if os(iOS)

import SwiftUI
import Turbocharger

public struct ScrollContainer<Content: View>: View {
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
        HostingScrollViewAdapter(
            axis,
            showsIndicators: showsIndicators,
            isPagingEnabled: isPagingEnabled,
            bounces: bounces
        ) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

// MARK: - Previews

struct ScrollContainer_Previews: PreviewProvider {
    static var previews: some View {
        ScrollContainer {
            VStack {
                ForEach(1...10, id: \.self) { i in
                    Text("Row \(i)")
                }
            }
            .background(Color.red)
        }
        .background(Color.blue)
    }
}

#endif
