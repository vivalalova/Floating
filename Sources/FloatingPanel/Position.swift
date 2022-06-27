//
//  Position.swift
//  FloatingPanel
//
//  Created by Lova on 2022/6/27.
//

import SwiftUI

public
extension Floating {
    enum CardPosition {
        case full
        case tall
        case compact
        case short
        case closed

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
            case .closed:
                return readerHeight
            case let .custom(toTop):
                return toTop
            }
        }
    }
}
