//
//  Created by lova on 2020/10/20.
//

import Combine
import SwiftUI

public
enum SheetOver {
    public
    struct SheetView<Content: View>: View {
        @Binding var position: Position

        @Binding var allowed: [Position]

        var content: () -> Content

        @GestureState private var dragState = DragState.inactive

        // PreferenceKeys
        @State private var topBarColor: Color = .gray
        @State private var backgroundColor: Color = .black
        @State private var animationCompletedClosure: () -> Void = {}
        @State private var backgroundOnTapClosure: () -> Void = {}

        @State var scrollable = true

        public
        var body: some View {
            GeometryReader { reader in
                let size = reader.size

                VStack(spacing: 0) { // card
                    self.content()
                        .onPreferenceChange(TopBarColorPreferenceKey.self) { color in
                            self.topBarColor = color
                        }
                        .onPreferenceChange(SheetOverBackgroundColorPreferenceKey.self) { color in
                            self.backgroundColor = color
                        }
                        .onPreferenceChange(AnimationCompletedPreferenceKey.self) { wrapped in
                            self.animationCompletedClosure = wrapped.closure
                        }
                        .onPreferenceChange(BackgroundTapPreferenceKey.self) { wrapped in
                            self.backgroundOnTapClosure = wrapped.closure
                        }
                        .environment(\.Scrollable, $scrollable)

                    Spacer()
                }
                .overlay(TopBar(color: topBarColor).padding(4), alignment: .top)
                .frame(height: UIScreen.main.bounds.height - self.offset(readerHeight: size.height))

                .background(UIColor.systemBackground.color)
                .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
                .shadow(color: self.shadowColor, radius: 10.0)

                .offsetAnimation(value: self.offset(readerHeight: size.height)) {
                    self.resetIfScrollable()
                    animationCompletedClosure()
                }
                .gesture(self.drag(readerHeight: size.height))
                .background(self.background(proxy: reader))
            }
            .onChange(of: position) { newValue in
                DispatchQueue.main.async {
                    if self.position != newValue {
                        self.position = newValue
                    }
                }
            }
        }

        /// 手放開的動畫完成時從 position 判斷該錨點是否要改變scrollable狀態
        /// 如果外部有使用sheetOverScrollable來套scrollview才會有實際作用
        private func resetIfScrollable() {
            let isPositionScrollable = self.position.isScrollable

            if isPositionScrollable != self.scrollable {
                self.scrollable = isPositionScrollable
            }
        }
    }
}

// MARK: - Drag

private
extension SheetOver.SheetView {
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
        let distance: CGFloat = self.position.distance(readerHeight: readerHeight)
        let delta = self.dragState.translation.height
        return max(distance + delta, 0)
    }

    /// shadowColor
    private var shadowColor: Color { Color(.sRGBLinear, white: 0, opacity: 0.13) }

    private typealias DragCB = _EndedGesture<_ChangedGesture<GestureStateGesture<DragGesture, DragState>>>
    private func drag(readerHeight: CGFloat) -> DragCB {
        DragGesture()
            .updating(self.$dragState) { drag, state, _ in
                state = .dragging(translation: drag.translation)
            }
            .onChanged { _ in
                // nothing
            }
            .onEnded { [self] drag in
                let verticalDirection = drag.predictedEndLocation.y - drag.location.y

                self.allowed.sort { a, b in a.distance(readerHeight: readerHeight) < b.distance(readerHeight: readerHeight) }

                guard let index = self.allowed.firstIndex(of: self.position) else {
                    return
                }

                if verticalDirection < 0, index - 1 >= 0, self.allowed.count > index - 1 { // 變高
                    self.position = self.allowed[index - 1]
                } else if verticalDirection > 0, self.allowed.count > index + 1 { // 變矮
                    self.position = self.allowed[index + 1]
                } else {
                    //
                }
            }
    }

    private func backgroundOpacity(readerHeight: CGFloat) -> Double {
        if self.position.distance(readerHeight: readerHeight) + self.dragState.translation.height == SheetOver.Position.short().distance(readerHeight: readerHeight) {
            return 0
        }

        let alpha: CGFloat = 0.6
        let opacity: CGFloat = alpha * 1 - (self.position.distance(readerHeight: readerHeight) + self.dragState.translation.height) / readerHeight

        return Double(min(opacity, alpha))
    }
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
}

private struct TopBar: View {
    let color: Color

    var body: some View {
        color
            .frame(width: 40, height: 5.0)
            .clipShape(Capsule())
            .padding(5)
    }
}

// MARK: - SubViews

private
extension SheetOver.SheetView {
    private func background(proxy: GeometryProxy) -> some View {
        self.backgroundColor
            .opacity(self.backgroundOpacity(readerHeight: proxy.size.height))
            .onTapGesture {
                self.backgroundOnTapClosure()
            }
            .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Preview

import MapKit

struct SheetOverCard_Previews: PreviewProvider {
    class Model: ObservableObject {
        @Published var position: SheetOver.Position = .short()
        @Published var allowed: [SheetOver.Position] = [.tall(scrollable: true), .half(), .short()]
    }

    @StateObject static var model = Model()

    static var previews: some View {
        Group {
            Map(coordinateRegion: .constant(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))))
                .edgesIgnoringSafeArea(.all)
                .sheetOver($model.position, allowed: $model.allowed) {
                    VStack(spacing: 0) {
                        Text("title")
                            .font(.title)

                        Divider()

                        LazyVStack {
                            ForEach(1 ..< 55) { _ in
                                Text("hihi")
                                    .font(.largeTitle)
                            }
                        }
                        .sheetOverScrollable()
                    }
                    .padding(.top, 20)
                    .sheetOverTopBarColor(.red)
                    .sheetOverBackgroundColor(.blue)
                }

            Color.green
                .sheetOver($model.position, allowed: .constant([.full(), .toBottom(240)])) {
                    NavigationView {
                        List {
                            ForEach(1 ..< 50) { _ in
                                Text("hihi")
                            }
                        }
                        .navigationTitle("hihihi2")
                    }
                }

            NavigationView {
                List {
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                }
            }.sheetOver($model.position, allowed: .constant([.toTop(120), .toBottom(240)])) {
                VStack {
                    ForEach(1 ..< 10) { _ in
                        Text("hihi")
                    }
                }
            }
        }
    }
}
