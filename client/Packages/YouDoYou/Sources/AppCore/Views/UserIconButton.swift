import SwiftUI

struct UserIconButton: View {
  @EnvironmentObject var navigationState: NavigationState
  @EnvironmentObject var authState: AuthState

  var body: some View {
    Button {
      navigationState.isShowingSettings = true
    } label: {
      if let photoURL = authState.user?.photoURL {
        AsyncImage(url: photoURL) { image in
          image
            .resizable()
            .scaledToFill()
        } placeholder: {
          Circle()
            .fill(Color(.systemGray5))
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
      }
      else {
        Circle()
          .fill(Color(.systemGray5))
          .frame(width: 32, height: 32)
      }
    }
  }
}
