import SwiftUI

struct TopicSelectionView: View {
  @EnvironmentObject var appState: AppState

  var body: some View {

    ScrollView {
      LazyVStack {
        ForEach(appState.domains) { domain in
          DomainItem(domain: domain)
        }
      }
    }
    .navigationTitle("Topics")
    .toolbarTitleDisplayMode(.automatic)
    #if os(iOS)
      .toolbarBackground(.hidden, for: .navigationBar)
    #endif
    .background(Color.systemGroupedBackground)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        UserIconButton()
      }
    }

  }

}
