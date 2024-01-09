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

// MARK: - OffsetAnimationCompleted

struct Wrapper: Equatable {
    static func == (lhs: Wrapper, rhs: Wrapper) -> Bool {
        true
    }

    var closure: () -> Void = {}
}

struct AnimationCompletedPreferenceKey: PreferenceKey {
    typealias Value = Wrapper

    static var defaultValue = Value()

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

public extension View {
    func sheetOverAnimationCompleted(_ offsetAnimationCompleted: @escaping () -> Void) -> some View {
        self.preference(
            key: AnimationCompletedPreferenceKey.self,
            value: Wrapper(closure: offsetAnimationCompleted)
        )
    }
}

// MARK: - On Background Tap

struct BackgroundTapPreferenceKey: PreferenceKey {
    typealias Value = Wrapper

    static var defaultValue = Value()

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

public extension View {
    func sheetOverBackgroundOnTap(_ onTap: @escaping () -> Void) -> some View {
        self.preference(
            key: BackgroundTapPreferenceKey.self,
            value: Wrapper(closure: onTap)
        )
    }
}
