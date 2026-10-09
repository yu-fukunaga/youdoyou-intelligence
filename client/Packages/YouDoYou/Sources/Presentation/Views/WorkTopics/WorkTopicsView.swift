import Domain
import SwiftUI

public struct WorkTopicsView: View {
  private let workTopics: [WorkTopic]
  @EnvironmentObject private var appState: AppState
  @State private var startingWorkTopic: WorkTopic?
  @State private var editingWorkTopic: WorkTopic?
  @State private var deletingWorkTopic: WorkTopic?
  @State private var isShowingCreate = false

  public init(workTopics: [WorkTopic]) {
    self.workTopics = workTopics
  }

  private var isDeleteAlertPresented: Binding<Bool> {
    Binding(
      get: { deletingWorkTopic != nil },
      set: { if !$0 { deletingWorkTopic = nil } }
    )
  }

  public var body: some View {
    ZStack(alignment: .bottomTrailing) {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(workTopics) { workTopic in
            WorkTopicRow(
              workTopic: workTopic,
              onStart: { startingWorkTopic = workTopic },
              onEdit: { editingWorkTopic = workTopic },
              onDelete: { deletingWorkTopic = workTopic }
            )
          }
        }
        .padding(16)
      }

      Button {
        isShowingCreate = true
      } label: {
        Image(systemName: "plus")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.white)
          .frame(width: 56, height: 56)
          .background(Color.blue)
          .clipShape(Circle())
          .shadow(radius: 4)
      }
      .padding(24)
    }
    .navigationTitle("Topics")
    .background(Color.systemGroupedBackground)
    .sheet(item: $startingWorkTopic) { workTopic in
      WorkLogCreateView(workTopicId: workTopic.id)
        .presentationCornerRadius(16)
    }
    #if os(iOS)
      .sheet(isPresented: $isShowingCreate) {
        WorkTopicFormView(mode: .create)
      }
      .sheet(item: $editingWorkTopic) { workTopic in
        WorkTopicFormView(mode: .edit(workTopic))
      }
    #endif
    .alert("このトピックを削除しますか？", isPresented: isDeleteAlertPresented, presenting: deletingWorkTopic) { workTopic in
      Button("削除", role: .destructive) {
        Task { try? await appState.workTopicRepository.delete(id: workTopic.id) }
      }
      Button("キャンセル", role: .cancel) {}
    } message: { _ in
      Text("この操作は取り消せません")
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
