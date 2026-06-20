import SwiftUI

@MainActor
class NavigationState: ObservableObject {
  @Published var isShowingSettings = false
  @Published var isShowingActivityCreate = false
}
