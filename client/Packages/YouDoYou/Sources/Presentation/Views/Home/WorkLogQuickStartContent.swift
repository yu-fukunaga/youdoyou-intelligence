import Domain
import SwiftUI

struct WorkLogQuickStartContent: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var viewModel: WorkLogQuickStartViewModel

  init(repository: any WorkLogRepositoryProtocol) {
    _viewModel = StateObject(wrappedValue: WorkLogQuickStartViewModel(repository: repository))
  }

  var body: some View {
    HStack(spacing: 12) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(viewModel.recentWorkTopics(in: appState.workTopics)) { workTopic in
            workTopicThumbnail(workTopic)
              .frame(width: 44, height: 44)
              .clipShape(RoundedRectangle(cornerRadius: 10))
          }
        }
      }

      Divider()
        .frame(height: 40)

      NavigationLink(destination: WorkTopicsView(workTopics: appState.workTopics)) {
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

  @ViewBuilder
  private func workTopicThumbnail(_ workTopic: WorkTopic) -> some View {
    if let urlString = workTopic.imageUrl, let url = URL(string: urlString), !urlString.isEmpty {
      AsyncImage(url: url) { image in
        image
          .resizable()
          .scaledToFill()
      } placeholder: {
        Color.systemGray5
      }
    }
    else {
      Color.systemGray5
    }
  }
}
