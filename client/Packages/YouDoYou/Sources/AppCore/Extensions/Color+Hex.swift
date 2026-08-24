import SwiftUI
import UIKit

extension Color {
  init?(hex: String) {
    var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexString.removeAll { $0 == "#" }

    guard hexString.count == 6, let value = UInt64(hexString, radix: 16) else {
      return nil
    }

    let red = Double((value >> 16) & 0xFF) / 255
    let green = Double((value >> 8) & 0xFF) / 255
    let blue = Double(value & 0xFF) / 255
    self.init(red: red, green: green, blue: blue)
  }

  var hexString: String {
    // getRed(_:green:blue:alpha:) fails for colors backed by a non-RGB color space
    // (e.g. white/black/gray), so convert through deviceRGB first to guarantee components.
    guard
      let rgbColor = UIColor(self).cgColor.converted(
        to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil),
      let components = rgbColor.components, components.count >= 3
    else {
      return "#000000"
    }
    return String(
      format: "#%02X%02X%02X",
      Int(components[0] * 255),
      Int(components[1] * 255),
      Int(components[2] * 255)
    )
  }
}
