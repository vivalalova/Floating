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

        let allowedPositions: [CardPosition]

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
                .overlay(TopBar(color: .gray), alignment: .top)
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
                if self.position != newValue {
                    self.position = newValue
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
                let cardTopEdgeLocation = self.position.distance(readerHeight: readerHeight) + drag.translation.height
                let fromPosition: Floating.CardPosition
                let toPosition: Floating.CardPosition
                let closestPosition: Floating.CardPosition

                if cardTopEdgeLocation <= Floating.CardPosition.compact.distance(readerHeight: readerHeight) {
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
                    self.position = toPosition
                } else if verticalDirection < 0 { // 變高
                    self.position = fromPosition
                } else {
                    self.position = closestPosition
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
        @Published var shortPosition: Floating.CardPosition = .short

        @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        @Published var text = ""

        func enabled() -> Bool {
            switch self.tallPosition {
            case .tall:
                return false
            default:
                return true
            }
        }
    }

    @StateObject static var model = Model()

    static var previews: some View {
        Group {
            Color.green
                .previewDisplayName("tall")
                .sheetOver(position: $model.tallPosition, allowedPositions: [.tall, .short]) {
                    NavigationView {
                        List {
                            ForEach(1 ..< 50) { _ in
                                Text("hihi")
                            }
                        }
                        .navigationTitle("hihihi2")
                    }
                }

            Color.red
                .edgesIgnoringSafeArea(.all)
                .sheetOver(position: $model.shortPosition, allowedPositions: [.tall, .short]) {
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

            Map(coordinateRegion: $model.region)
                .edgesIgnoringSafeArea(.all)
                .sheetOver(position: $model.shortPosition, allowedPositions: [.tall, .short]) {
                    ScrollView {
                        C()
                    }
                    .padding(.top, 20)
                    .disabled(model.enabled())
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
            }.sheetOver(position: $model.shortPosition) {
                VStack {
                    ForEach(1 ..< 10) { _ in
                        Text("hihi")
                    }
                }
            }
        }
    }

    struct C: View {
        var body: some View {
            VStack {
                HStack {
                    Image(systemName: "person")
                    Text("hihihi")

                    Spacer()

                    Image(systemName: "arrow.down")
                }
                .padding(.horizontal)

                Divider()

                VStack {
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                }.font(.largeTitle)

                VStack {
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                }
                .font(.largeTitle)

                VStack {
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                    Text("hihi")
                }
                .font(.largeTitle)
            }
        }
    }
}
