import SwiftUI

extension Color {
  static var systemGroupedBackground: Color {
    #if os(iOS)
      Color(uiColor: .systemGroupedBackground)
    #elseif canImport(AppKit)
      Color(nsColor: .underPageBackgroundColor)
    #endif
  }

  static var secondarySystemGroupedBackground: Color {
    #if os(iOS)
      Color(uiColor: .secondarySystemGroupedBackground)
    #elseif canImport(AppKit)
      Color(nsColor: .controlBackgroundColor)
    #endif
  }

  static var systemBackground: Color {
    #if os(iOS)
      Color(uiColor: .systemBackground)
    #elseif canImport(AppKit)
      Color(nsColor: .windowBackgroundColor)
    #endif
  }

  static var systemFill: Color {
    #if os(iOS)
      Color(uiColor: .systemFill)
    #elseif canImport(AppKit)
      Color(nsColor: .quaternaryLabelColor)
    #endif
  }

  static var separator: Color {
    #if os(iOS)
      Color(uiColor: .separator)
    #elseif canImport(AppKit)
      Color(nsColor: .separatorColor)
    #endif
  }

  static var systemGray: Color {
    #if os(iOS)
      Color(uiColor: .systemGray)
    #elseif canImport(AppKit)
      Color(nsColor: .systemGray)
    #endif
  }

  static var systemGray4: Color {
    #if os(iOS)
      Color(uiColor: .systemGray4)
    #elseif canImport(AppKit)
      Color(nsColor: .systemGray).opacity(0.3)
    #endif
  }

  static var systemGray5: Color {
    #if os(iOS)
      Color(uiColor: .systemGray5)
    #elseif canImport(AppKit)
      Color(nsColor: .systemGray).opacity(0.2)
    #endif
  }

  static var systemGray6: Color {
    #if os(iOS)
      Color(uiColor: .systemGray6)
    #elseif canImport(AppKit)
      Color(nsColor: .systemGray).opacity(0.1)
    #endif
  }
}
