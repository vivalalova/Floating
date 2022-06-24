//
//  Created by lova on 2020/12/7.
//

import Combine
import SwiftUI

public extension View {
    /// Calls the completion handler whenever an animation on the given value completes.
    /// - Parameters:
    ///   - value: The value to observe for animations.
    ///   - completion: The completion callback to call once the animation completes.
    /// - Returns: A modified `View` instance with the observer attached.
    func onAnimationCompleted<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) -> ModifiedContent<Self, AnimationCompletionObserverModifier<Value>> {
        modifier(AnimationCompletionObserverModifier(observedValue: value, completion: completion))
    }
}

public
struct AnimationCompletionObserverModifier<Value>: AnimatableModifier where Value: VectorArithmetic {
    private var targetValue: Value
    private var completion: () -> Void

    public
    var animatableData: Value {
        didSet {
            self.notifyCompletionIfFinished()
        }
    }

    init(observedValue: Value, completion: @escaping () -> Void) {
        self.completion = completion
        self.animatableData = observedValue
        self.targetValue = observedValue
    }

    public
    func body(content: Content) -> some View {
        return content
    }

    /// Verifies whether the current animation is finished and calls the completion callback if true.
    private func notifyCompletionIfFinished() {
        guard self.animatableData == self.targetValue else {
            return
        }

        DispatchQueue.main.async {
            self.completion()
        }
    }
}
