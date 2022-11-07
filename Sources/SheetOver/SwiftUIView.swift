//
//  SwiftUIView.swift
//
//
//  Created by Lova on 2022/11/7.
//

import SwiftUI

extension UIView {
    func swiftUIView() -> SwiftUIView<UIView> {
        SwiftUIView(view: self)
    }
}

extension UIViewController {
    func swiftUIView() -> SwiftUIViewController<UIViewController> {
        SwiftUIViewController(view: self)
    }
}

struct SwiftUIView<T: UIView>: UIViewRepresentable {
    var root: T

    init(view: T) {
        self.root = view
    }

    func makeUIView(context: Context) -> T {
        self.root
    }

    func updateUIView(_ uiView: T, context: Context) {}
}

struct SwiftUIViewController<T: UIViewController>: UIViewControllerRepresentable {
    var root: T

    init(view: T) {
        self.root = view
    }

    func makeUIViewController(context: Context) -> T {
        self.root
    }

    func updateUIViewController(_ uiViewController: T, context: Context) {}
}

extension View {
    func uiViewController() -> UIViewController {
        UIHostingController(rootView: self)
    }

    func uiView() -> UIView {
        self.uiViewController().view
    }
}
