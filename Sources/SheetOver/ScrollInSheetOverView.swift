//
//  SwiftUIView.swift
//
//
//  Created by Lova on 2022/11/7.
//

import SwiftUI
import SwiftUIViewRepresentable

// MARK: - Extension for View

public
extension View {
    /// 內容高度會大於Sheet高度時使用, 讓他內容可以往下推或可以Scroll
    func sheetOverScrollable() -> some View {
        ScrollInSheetOverView {
            self
        }
    }
}

// MARK: - EnvironmentValues

extension EnvironmentValues {
    private struct IfScrolls: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(true)
    }

    var Scrollable: Binding<Bool> {
        get { self[IfScrolls.self] }
        set { self[IfScrolls.self] = newValue }
    }
}

// MARK: - ScrollInSheetOverView

public
struct ScrollInSheetOverView<Content: View>: UIViewRepresentable {
    public
    typealias ScrollViewType = MYScrollView

    /// SheetView那邊 allowed的錨點位置是否可scroll
    @Environment(\.Scrollable) var scrollable

    /// scrollview 內容長度是否大於frame.size.height
    @State var isContentSizeHigherThanFrameSize = false

    var content: Content

    public
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    public
    func makeUIView(context: Context) -> ScrollViewType {
        let scrollView = ScrollViewType($isContentSizeHigherThanFrameSize)

        scrollView.isScrollEnabled = true
        scrollView.automaticallyAdjustsScrollIndicatorInsets = false

        scrollView.delegate = context.coordinator

        let contentView = self.content.uiView()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)

        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

        return scrollView
    }

    public
    func updateUIView(_ uiView: ScrollViewType, context: Context) {
        uiView.isScrollEnabled = self.scrollable.wrappedValue && self.isContentSizeHigherThanFrameSize
    }

    public
    func makeCoordinator() -> Coordinator {
        Coordinator(scrollable: self.scrollable)
    }
}

// MARK: - MYScrollView

public
extension ScrollInSheetOverView {
    /// 幫UIScrollView加上判斷
    class MYScrollView: UIScrollView {
        @Binding var isContentSizeHigherThanFrameSize: Bool

        init(_ isContentSizeHigherThanFrameSize: Binding<Bool>) {
            self._isContentSizeHigherThanFrameSize = isContentSizeHigherThanFrameSize
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override public
        var frame: CGRect {
            didSet {
                // FIXME: Modifying state during view update, this will cause undefined behavior.
                self.isContentSizeHigherThanFrameSize = self.contentSize.height > self.frame.size.height
            }
        }
    }
}

// MARK: - Coordinator of UIScrollViewDelegate

public
extension ScrollInSheetOverView {
    class Coordinator: NSObject, UIScrollViewDelegate {
        @Binding var scrollable: Bool

        @State var lastContentOffset: CGFloat = 0

        init(scrollable: Binding<Bool>) {
            self._scrollable = scrollable
        }

        public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            self.lastContentOffset = scrollView.contentOffset.x
        }

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if scrollView.contentOffset.y < 0 {
                self.scrollable = false
            }

            if self.lastContentOffset > scrollView.contentOffset.x {
                print("up")
            } else if self.lastContentOffset < scrollView.contentOffset.x {
                print("down")
            } else {
                // didn't move
            }
        }
    }
}
