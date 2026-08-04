import SwiftUI

struct LoginView: View {
  @EnvironmentObject private var authState: AuthState
  @State private var errorMessage: String?
  @State private var isLoading = false

  var body: some View {
    VStack(spacing: 24) {
      Text("YouDoYou")
        .font(.largeTitle)
        .bold()

      // Google Sign In
      Button {
        Task {
          isLoading = true
          errorMessage = nil
          do {
            try await authState.signInWithGoogle()
          }
          catch {
            errorMessage = error.localizedDescription
          }
          isLoading = false
        }
      } label: {
        if isLoading {
          ProgressView()
            .frame(maxWidth: .infinity)
        }
        else {
          Text("Sign in with Google")
            .frame(maxWidth: .infinity)
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(isLoading)
      #if DEBUG
        .disabled(EnvUtils.isEmulator)
      #endif

      #if DEBUG
        Button {
          Task { await signInAsTestUser() }
        } label: {
          if isLoading {
            ProgressView()
              .frame(maxWidth: .infinity)
          }
          else {
            Text("Sign In as Test User")
              .frame(maxWidth: .infinity)
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading || !EnvUtils.isEmulator)

        Text(EnvUtils.isEmulator ? "Emulator" : "Dev")
          .font(.caption)
          .foregroundColor(.secondary)
      #endif

      if let errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .font(.caption)
      }
    }
    .padding(32)
    .frame(maxWidth: 320)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  #if DEBUG
    private func signInAsTestUser() async {
      isLoading = true
      errorMessage = nil
      do {
        try await authState.signInAsTestUser()
      }
      catch {
        errorMessage = error.localizedDescription
      }
      isLoading = false
    }
  #endif
}
