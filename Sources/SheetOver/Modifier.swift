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
        allowed: Binding<[SheetOver.Position]> = .constant([.tall, .half, .short]),
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
    let allowed: Binding<[SheetOver.Position]>

    let content: () -> T

    public func body(content: Content) -> some View {
        ZStack {
            content

            SheetOver.SheetView(position: position, allowed: allowed) {
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
