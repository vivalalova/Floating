//
//  Created by lova on 2020/10/20.
//

import SwiftUI

public
extension View {
    func sheetOver<T: View>(
        isPresented: Binding<Bool>,
        position: SheetView<T>.CardPosition = .tall,
        dismissable: Bool = false,
        onDismiss: (() -> Void)? = nil,
        allowedPositions: [SheetView<T>.CardPosition] = [.tall, .compact, .short],
        content: @escaping () -> T
    ) -> some View {
        self.modifier(SheetViewModifier(
            position: position,
            isShow: { isPresented.wrappedValue },
            dismissable: dismissable,
            onDismiss: onDismiss,
            allowedPositions: allowedPositions,
            content: content,
            done: { isPresented.wrappedValue = false }
        ))
    }
}

public
struct SheetViewModifier<T: View>: ViewModifier {
    typealias CB = () -> Void

    let position: SheetView<T>.CardPosition

    let isShow: () -> Bool

    let dismissable: Bool
    let onDismiss: CB?

    let allowedPositions: [SheetView<T>.CardPosition]

    let content: () -> T

    let done: CB

    public func body(content: Content) -> some View {
        ZStack {
            content

            if isShow() {
                SheetView(
                    position: position,
                    didClose: self.sheetOverCardDidClose(dismissable: dismissable),
                    allowedPositions: allowedPositions
                ) {
                    self.content()
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
    }

    private func sheetOverCardDidClose(dismissable: Bool) -> CB? {
        guard dismissable else {
            return nil
        }

        return {
            self.done()
            self.onDismiss?()
        }
    }
}

public
struct SheetView<Content: View>: View {
    @State var position: CardPosition
//    {
//        didSet {
//            if self.position == .close {
//                withAnimation {
//                    self.forClose = 0
//                }
//            }
//        }
//    }

    @State var didClose: (() -> Void)? = nil
    @State private var forClose = 1.0
    var isCloseable: Bool { self.didClose != nil }

    @State private var animated = true

    /// return if close
    @State private var didTapTop: () -> Bool = { true }

    let allowedPositions: [SheetView<Content>.CardPosition]

    var content: () -> Content

    @GestureState private var dragState = DragState.inactive

    @State private var height: CGFloat = 0

    public
    var body: some View {
        GeometryReader { reader in
            VStack(spacing: 0) { // card
                VStack(spacing: 0) {
                    self.content()
                    Spacer()
                }
                .overlay(TopBar(), alignment: .top)
                .frame(
                    width: UIScreen.main.bounds.size.width,
                    height: reader.size.height - self.position.distance(readerHeight: reader.size.height)
                )

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .cornerRadius(16.0)
            .shadow(color: self.shadowColor, radius: 10.0)
            .offset(x: self.offset(proxy: reader).x,
                    y: self.offset(readerHeight: reader.size.height))
            .animation(.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0))
            .gesture(self.drag(readerHeight: reader.size.height))
            .background(self.background(proxy: reader))
            .onAnimationCompleted(for: self.forClose) {
                self.didClose?()
            }
        }
    }

    public
    enum CardPosition {
        case full
        case tall
        case compact
        case short
        case close

        case custom(toTop: CGFloat)

        public
        func distance(readerHeight: CGFloat) -> CGFloat {
            switch self {
            case .full:
                return 0
            case .tall:
                return 80
            case .compact:
                return readerHeight * 0.5
            case .short:
                return readerHeight - 200
            case .close:
                return readerHeight
            case let .custom(toTop):
                return toTop
            }
        }
    }
}

// MARK: - Animation

private
extension SheetView {
    /// 移回銀幕左側
    /// - Parameter proxy: GeometryProxy
    /// - Returns: 用來修正的offset
    private func offset(proxy: GeometryProxy) -> CGPoint {
        let originOnScreen = proxy.frame(in: CoordinateSpace.global).origin
        return CGPoint(x: -originOnScreen.x, y: -originOnScreen.y)
    }

    /// 計算前景位置
    /// - Parameter readerHeight: geometryProxy.size.height
    /// - Returns: offset.y
    private func offset(readerHeight: CGFloat) -> CGFloat {
        let distance = self.position.distance(readerHeight: readerHeight)
        let delta = self.dragState.translation.height
        return max(distance + delta, 0)
    }

    /// shadowColor
    private var shadowColor: Color { Color(.sRGBLinear, white: 0, opacity: 0.13) }

    private typealias DragCB = _EndedGesture<_ChangedGesture<GestureStateGesture<DragGesture, SheetView<Content>.DragState>>>
    private func drag(readerHeight: CGFloat) -> DragCB {
        DragGesture()
            .updating(self.$dragState) { drag, state, _ in
                state = .dragging(translation: drag.translation)
            }
            .onChanged { _ in
                self.height = readerHeight - self.position.distance(readerHeight: readerHeight)
            }
            .onEnded { [self] drag in
                let verticalDirection = drag.predictedEndLocation.y - drag.location.y
                let cardTopEdgeLocation = self.position.distance(readerHeight: readerHeight) + drag.translation.height
                let fromPosition: CardPosition
                let toPosition: CardPosition
                let closestPosition: CardPosition

                if cardTopEdgeLocation <= CardPosition.compact.distance(readerHeight: readerHeight) {
                    fromPosition = .tall
                    toPosition = .compact
                } else {
                    fromPosition = .compact
                    toPosition = .short
                }

                if (cardTopEdgeLocation - fromPosition.distance(readerHeight: readerHeight)) < (toPosition.distance(readerHeight: readerHeight) - cardTopEdgeLocation) {
                    closestPosition = fromPosition
                } else {
                    closestPosition = toPosition
                }

                if verticalDirection > 0 { // 變矮
                    if self.isCloseable {
                        self.position = .close
                    } else {
                        self.position = toPosition
                    }
                } else if verticalDirection < 0 { // 變高
                    self.position = fromPosition
                } else {
                    self.position = closestPosition
                }
            }
    }

    private typealias GestureCB = (DragGesture.Value) -> Void
    private func backgroundOpacity(readerHeight: CGFloat) -> Double {
        if self.position.distance(readerHeight: readerHeight) + self.dragState.translation.height == CardPosition.short.distance(readerHeight: readerHeight) {
            return 0
        }

        let opacity = 0.6 * (1 - (self.position.distance(readerHeight: readerHeight) + self.dragState.translation.height) / readerHeight)
        return Double(opacity > 0.4 ? 0.4 : opacity)
    }

    private enum DragState {
        case inactive
        case dragging(translation: CGSize)

        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case let .dragging(translation):
                return translation
            }
        }

        var isDragging: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }
}

// MARK: - SubViews

private
extension SheetView {
    private struct TopBar: View {
        var body: some View {
            Color.secondary
                .frame(width: 40, height: 5.0)
                .clipShape(Capsule())
                .padding(5)
        }
    }

    private func background(proxy: GeometryProxy) -> some View {
        Color.black
            .offset(
                x: self.offset(proxy: proxy).x,
                y: self.offset(proxy: proxy).y
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(self.backgroundOpacity(readerHeight: proxy.size.height))
            .onTapGesture {
                let shouldClose = self.didTapTop()
                if self.isCloseable && shouldClose {
                    self.position = .close
                }
            }
            .edgesIgnoringSafeArea(.all)
    }
}

struct SheetOverCard_Previews: PreviewProvider {
    class Model: ObservableObject {
        @Published var isPresented = true
    }

    @StateObject static var model = Model()

    static var previews: some View {
        Group {
            Color.red
                .previewDisplayName("tall")
                .edgesIgnoringSafeArea(.all)
                .sheetOver(isPresented: self.$model.isPresented, position: .tall) {
//                    NavigationView {
//                        List {
                    Group {
                        Group {
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                        }
                        Group {
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                        }
                    }
//                        }
//                        .navigationTitle("hihihihi")
//                    }
                }

            ZStack {
                Color.red
                    .edgesIgnoringSafeArea(.all)
                    .sheetOver(isPresented: self.$model.isPresented, position: .short, dismissable: true) {
                        List {
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                            Text("hihi")
                        }
                    }

                Button("oooo") {
                    self.model.isPresented.toggle()
                }
            }
        }
    }
}
