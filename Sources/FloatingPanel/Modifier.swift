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
        allowedPositions: Binding<[Floating.CardPosition]> = .constant([.tall, .half, .short]),
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
    let allowedPositions: Binding<[Floating.CardPosition]>

    let content: () -> T

    public func body(content: Content) -> some View {
        ZStack {
            content

            Floating.SheetView(position: position, allowedPositions: allowedPositions) {
                self.content()
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

extension UIColor {
    var color: Color {
        Color(self)
    }
}
