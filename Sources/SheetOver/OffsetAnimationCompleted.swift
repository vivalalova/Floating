//
//  OffsetAnimationCompleted.swift
//
//
//  Created by Lova on 2022/11/8.
//

import SwiftUI

typealias Closure = () -> Void

struct Wrapper: Equatable {
    static func == (lhs: Wrapper, rhs: Wrapper) -> Bool {
        true
    }

    var closure: Closure = {}
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
        self
            .preference(key: AnimationCompletedPreferenceKey.self, value: Wrapper(closure: offsetAnimationCompleted))
    }
}
