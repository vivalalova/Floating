//
//  Created by lova on 2020/10/20.
//

import Combine
import SwiftUI

public
enum Floating {
    public
    struct SheetView<Content: View>: View {
        @Binding var position: CardPosition

        @Binding var allowedPositions: [CardPosition]

        var content: () -> Content

        @GestureState private var dragState = DragState.inactive

        public
        var body: some View {
            GeometryReader { reader in
                let size = reader.size

                VStack(spacing: 0) { // card
                    VStack(spacing: 0) {
                        self.content()

                        Spacer()
                    }
                    .frame(width: size.width, height: size.height)

                    Spacer()
                }
                .overlay(TopBar(color: .gray).padding(4), alignment: .top)
                .frame(height: UIScreen.main.bounds.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(UIColor.systemBackground.color)
                .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
                .shadow(color: self.shadowColor, radius: 10.0)
                .offset(
                    // x: self.offset(proxy: reader).x,
                    y: self.offset(readerHeight: size.height)
                )
                .animation(.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0))
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
    }
}

// MARK: - Animation

private
extension Floating.SheetView {
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
//                let cardTopEdgeLocation = self.position.distance(readerHeight: readerHeight) + drag.translation.height
//                let fromPosition: Floating.CardPosition
//                let toPosition: Floating.CardPosition
//                let closestPosition: Floating.CardPosition

                self.allowedPositions
                    .sort { a, b in a.distance(readerHeight: readerHeight) < b.distance(readerHeight: readerHeight) }

                guard let index = self.allowedPositions.firstIndex(of: self.position) else {
                    return
                }

                if verticalDirection < 0, index - 1 >= 0, self.allowedPositions.count > index - 1 { // 變高
                    self.position = self.allowedPositions[index - 1]
                } else if verticalDirection > 0, self.allowedPositions.count > index + 1 { // 變矮
                    self.position = self.allowedPositions[index + 1]
                } else {
                    //
                }
            }
    }

    private func backgroundOpacity(readerHeight: CGFloat) -> Double {
        if self.position.distance(readerHeight: readerHeight) + self.dragState.translation.height == Floating.CardPosition.short.distance(readerHeight: readerHeight) {
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
extension Floating.SheetView {
    private func background(proxy: GeometryProxy) -> some View {
        Color.black
//            .offset(
//                x: self.offset(proxy: proxy).x,
//                y: self.offset(proxy: proxy).y
//            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(self.backgroundOpacity(readerHeight: proxy.size.height))
            .onTapGesture {
                print("maybe should close")
            }
            .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Preview

import MapKit

struct SheetOverCard_Previews: PreviewProvider {
    class Model: ObservableObject {
        @Published var tallPosition: Floating.CardPosition = .tall
        @Published var shortPosition: Floating.CardPosition = .toBottom(240)

        @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        @Published var text = ""
    }

    @StateObject static var model = Model()

    static var previews: some View {
        Group {
            Map(coordinateRegion: $model.region)
                .edgesIgnoringSafeArea(.all)
                .sheetOver($model.shortPosition, allowedPositions: .constant([.tall, .toBottom(240)])) {
                    ScrollView {
                        LazyVStack {
                            HStack {
                                Image(systemName: "person")
                                Text("username")

                                Spacer()

                                Button {
                                    if self.model.shortPosition == .tall {
                                        self.model.shortPosition = .toBottom(240)
                                    } else {
                                        self.model.shortPosition = .tall
                                    }
                                } label: {
                                    if self.model.shortPosition == .toBottom(240) {
                                        Image(systemName: "arrow.down")
                                    } else {
                                        Image(systemName: "arrow.up")
                                    }
                                }
                            }
                            .padding(.horizontal)

                            Divider()

                            Divider()

                            ForEach(1 ..< 100) { _ in
                                Text("hihi")
                                    .font(.largeTitle)
                            }
                        }
                    }
                    .padding(.top, 20)
                }

            Color.green
                .sheetOver($model.tallPosition, allowedPositions: .constant([.tall, .short])) {
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
            }.sheetOver($model.shortPosition, allowedPositions: .constant([.tall, .toTop(120)])) {
                VStack {
                    ForEach(1 ..< 10) { _ in
                        Text("hihi")
                    }
                }
            }
        }
    }
}
