//
//  File.swift
//
//
//  Created by Lova on 2022/7/19.
//

import SwiftUI

// MARK: - 上面小槓槓的顏色

struct TopBarColorPreferenceKey: PreferenceKey {
    typealias Value = Color

    static var defaultValue: Color = .gray

    static func reduce(value: inout Color, nextValue: () -> Color) {
        value = nextValue()
    }
}

public
extension View {
    /// TopBar 的顏色
    func sheetOverTopBarColor(_ color: Color) -> some View {
        self.preference(key: TopBarColorPreferenceKey.self, value: color)
    }
}

// MARK: - 背後的顏色

struct SheetOverBackgroundColorPreferenceKey: PreferenceKey {
    typealias Value = Color

    static var defaultValue: Color = .gray

    static func reduce(value: inout Color, nextValue: () -> Color) {
        value = nextValue()
    }
}

public
extension View {
    /// 背後變黑的顏色
    func sheetOverBackgroundColor(_ color: Color) -> some View {
        self.preference(key: SheetOverBackgroundColorPreferenceKey.self, value: color)
    }
}
