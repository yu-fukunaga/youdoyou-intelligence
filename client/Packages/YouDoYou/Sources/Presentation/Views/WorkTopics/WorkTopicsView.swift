import Domain
import SwiftUI

public struct WorkTopicsView: View {
  private let workTopics: [WorkTopic]
  @State private var startingWorkTopic: WorkTopic?

  public init(workTopics: [WorkTopic]) {
    self.workTopics = workTopics
  }

  public var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(workTopics) { workTopic in
          WorkTopicRow(workTopic: workTopic) {
            startingWorkTopic = workTopic
          }
        }
      }
      .padding(16)
    }
    .navigationTitle("Topics")
    .background(Color.systemGroupedBackground)
    .sheet(item: $startingWorkTopic) { workTopic in
      WorkLogCreateView(workTopicId: workTopic.id)
        .presentationCornerRadius(16)
    }
  }
}

#Preview {
  NavigationStack {
    WorkTopicsView(
      workTopics: [
        WorkTopic(title: "YouDoYou Intelligence開発", imageUrl: "https://picsum.photos/seed/topic-001-1/400/400"),
        WorkTopic(title: "英単語ターゲット", imageUrl: "https://picsum.photos/seed/topic-002-1/400/400"),
        WorkTopic(title: "TOEIC英単語", imageUrl: "https://picsum.photos/seed/topic-003-1/400/400"),
        WorkTopic(title: "DeepLearning.AI", imageUrl: "https://picsum.photos/seed/topic-006-1/400/400"),
      ]
    )
  }
}
