//
//  Modifier.swift
//  SheetOver
//
//  Created by Lova on 2022/6/27.
//

import SwiftUI

public
extension View {
    func sheetOver<T: View>(
        _ position: Binding<SheetOver.Position>,
        allowed: [SheetOver.Position] = [.tall(), .half(), .short()],
        content: @escaping () -> T
    ) -> some View {
        self.modifier(
            SheetViewModifier(position: position, allowed: allowed, content: content)
        )
    }
}

public
struct SheetViewModifier<T: View>: ViewModifier {
    let position: Binding<SheetOver.Position>
    let allowed: [SheetOver.Position]

    let content: () -> T

    public func body(content: Content) -> some View {
        content
            .overlay(
                SheetOver.SheetView(position: self.position, allowed: self.allowed) {
                    self.content()
                }
                .edgesIgnoringSafeArea(.all)
            )
    }
}
