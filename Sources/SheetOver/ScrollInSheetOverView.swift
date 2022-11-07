//
//  SwiftUIView.swift
//
//
//  Created by Lova on 2022/11/7.
//

import SwiftUI

public
class MYScrollView: UIScrollView {
    @Binding var isNeedsScroll: Bool

    init(isNeedsScroll: Binding<Bool>) {
        self._isNeedsScroll = isNeedsScroll
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public
    var frame: CGRect {
        didSet {
            self.isNeedsScroll = self.contentSize.height > self.frame.size.height
        }
    }
}

public
struct ScrollInSheetOverView<Content: View>: UIViewRepresentable {
    public typealias ScrollViewType = MYScrollView

    @Binding var scrollable: Bool

    var content: Content

    public
    init(scrollable: Binding<Bool> = .constant(true), @ViewBuilder content: @escaping () -> Content) {
        self._scrollable = scrollable
        self.content = content()
    }

    @State var needsScroll = false

    public
    func makeUIView(context: Context) -> ScrollViewType {
        let scrollView = ScrollViewType(isNeedsScroll: $needsScroll)

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
        uiView.isScrollEnabled = self.scrollable && self.needsScroll
    }

    public
    func makeCoordinator() -> Coordinator {
        Coordinator(scrollable: self.$scrollable)
    }

    public
    class Coordinator: NSObject, UIScrollViewDelegate {
        @Binding var scrollable: Bool

        init(scrollable: Binding<Bool>) {
            self._scrollable = scrollable
        }

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if scrollView.contentOffset.y < 0 {
                self.scrollable = false
            }
        }
    }
}
