//
//  Color+Hex.swift
//  Samaali
//
//  Created by Claude Code on 2/2/26.
//

import SwiftUI

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count
        let r, g, b, a: Double

        switch length {
        case 6: // RGB (e.g., "007AFF")
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        case 8: // ARGB (e.g., "FF007AFF")
            a = Double((rgb & 0xFF000000) >> 24) / 255.0
            r = Double((rgb & 0x00FF0000) >> 16) / 255.0
            g = Double((rgb & 0x0000FF00) >> 8) / 255.0
            b = Double(rgb & 0x000000FF) / 255.0
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    func toHex(includeAlpha: Bool = false) -> String? {
        guard let components = UIColor(self).cgColor.components else {
            return nil
        }

        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r
        let a = components.count > 3 ? components[3] : 1.0

        if includeAlpha {
            return String(
                format: "#%02X%02X%02X%02X",
                Int(a * 255),
                Int(r * 255),
                Int(g * 255),
                Int(b * 255)
            )
        } else {
            return String(
                format: "#%02X%02X%02X",
                Int(r * 255),
                Int(g * 255),
                Int(b * 255)
            )
        }
    }
}
