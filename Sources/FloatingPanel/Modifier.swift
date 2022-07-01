//
//  Modifier.swift
//  FloatingPanel
//
//  Created by Lova on 2022/6/27.
//

import SwiftUI

public
extension View {
    func sheetOver<T: View>(
        position: Binding<Floating.CardPosition>,
        allowedPositions: [Floating.CardPosition] = [.tall, .compact, .short],
        content: @escaping () -> T
    ) -> some View {
        self.modifier(
            SheetViewModifier(
                position: position,
                allowedPositions: allowedPositions,
                content: content
            )
        )
    }
}

public
struct SheetViewModifier<T: View>: ViewModifier {
    let position: Binding<Floating.CardPosition>
    let allowedPositions: [Floating.CardPosition]

    let content: () -> T

    public func body(content: Content) -> some View {
        content
            .overlay(
                Floating.SheetView(position: self.position, allowedPositions: self.allowedPositions) {
                    self.content()
                }
            )
    }
}

extension UIColor {
    var color: Color {
        Color(self)
    }
}
