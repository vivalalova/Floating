//
//  Position.swift
//  FloatingPanel
//
//  Created by Lova on 2022/6/27.
//

import SwiftUI

public
extension Floating {
    enum CardPosition: Equatable {
        case full
        case tall
        case compact
        case short
        case closed

        case toTop(_ distance: CGFloat)
        case toBottom(_ distance: CGFloat)

        /// Top Distance to SafeArea
        /// - Parameter readerHeight: self height
        /// - Returns: distance to safe area
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
            case .closed:
                return readerHeight
            case let .toTop(distance):
                return distance
            case let .toBottom(distance):
                return readerHeight - distance
            }
        }
    }
}
