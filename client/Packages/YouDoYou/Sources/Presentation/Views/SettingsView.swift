import SwiftUI

public struct SettingsView: View {
  @EnvironmentObject private var authState: AuthState

  public init() {}

  public var body: some View {
    List {
      Section("System") {
        HStack {
          Text("Version")
          Spacer()
          Text("1.0.0").foregroundColor(.secondary)
        }
      }

      Section {
        Button(role: .destructive) {
          try? authState.signOut()
        } label: {
          Text("Sign Out")
        }
      }
    }
    .navigationTitle("Settings")
  }
}
