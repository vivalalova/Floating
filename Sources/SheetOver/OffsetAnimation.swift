//
//  SwiftUIView.swift
//
//
//  Created by Lova on 2022/11/6.
//

import SwiftUI

struct OffsetAnimation: GeometryEffect {
    typealias T = CGFloat
    var animatableData: T {
        didSet {
            self.animatableDataSetAction()
        }
    }

    private func animatableDataSetAction() {
        guard self.animatableData == self.targetValue else { return }
        DispatchQueue.main.async {
            self.onCompletion()
        }
    }

    var targetValue: T
    init(value: T, onCompletion: @escaping () -> Void) {
        self.targetValue = value
        self.animatableData = value
        self.onCompletion = onCompletion
    }

    var onCompletion: () -> Void

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 0, y: self.animatableData))
    }
}

extension View {
    func offsetAnimation(value: CGFloat, completed: @escaping () -> Void) -> some View {
        self
            .modifier(OffsetAnimation(value: value, onCompletion: completed))
            .animation(.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0), value: value)
    }
}
