import SwiftUI

struct WorkLogQuickStartContent: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel = WorkLogQuickStartViewModel()

  var body: some View {
    HStack(spacing: 12) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(viewModel.recentTopics(in: appState.domains)) { topic in
            Text(topic.title)
              .font(.footnote)
              .fontWeight(.medium)
              .foregroundColor(.primary)
              .padding(.vertical, 8)
              .padding(.horizontal, 12)
              .background(Color(uiColor: .systemGray6))
              .cornerRadius(16)
          }
        }
      }

      Divider()
        .frame(height: 40)

      NavigationLink(destination: TopicSelectionView()) {
        VStack(spacing: 4) {
          Image(systemName: "folder.fill")
            .font(.title2)
            .foregroundColor(.indigo)

          Text("すべて")
            .font(.caption2)
            .foregroundColor(.primary)
        }
        .frame(width: 56)
      }
    }
    .onAppear { viewModel.startObserving() }
    .onDisappear { viewModel.stopObserving() }
  }
}
