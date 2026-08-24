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
    .navigationBarTitleDisplayMode(.large)
    .toolbarBackground(.hidden, for: .navigationBar)
    .background(Color(.systemGroupedBackground))
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        UserIconButton()
      }
    }

  }

}
