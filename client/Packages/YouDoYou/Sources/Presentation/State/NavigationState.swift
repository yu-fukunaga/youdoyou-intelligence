import SwiftUI

@MainActor
public class NavigationState: ObservableObject {
  @Published public var isShowingSettings = false
  @Published public var isShowingWorkLogCreate = false

  public init() {}
}
