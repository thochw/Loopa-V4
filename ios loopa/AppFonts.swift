//
//  AppFonts.swift
//  ios loopa
//
//  Created by Cursor on 2026-01-27.
//

import SwiftUI

extension Font {
    static func app(size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle? = nil) -> Font {
        let name: String

        switch weight {
        case .semibold, .bold, .heavy, .black:
            name = "WorkSans-SemiBold"
        default:
            name = "WorkSans-Medium"
        }

        if let textStyle = textStyle {
            return .custom(name, size: size, relativeTo: textStyle)
        }

        return .custom(name, size: size)
    }
}
