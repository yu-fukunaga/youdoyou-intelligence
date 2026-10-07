import Domain
import SwiftUI

public struct TimerBanner: View {
  @Environment(WorkLogDraftStore.self) var workLogDraftStore: WorkLogDraftStore
  @EnvironmentObject var appState: AppState
  var onTap: () -> Void

  public init(onTap: @escaping () -> Void) {
    self.onTap = onTap
  }

  private var workTopic: WorkTopic? {
    appState.workTopics.first { $0.id == workLogDraftStore.activeWorkTopicId }
  }

  public var body: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(Color.red)
        .frame(width: 8, height: 8)

      VStack(alignment: .leading, spacing: 2) {
        Text(workTopic?.title ?? "")
          .font(.subheadline)
          .fontWeight(.semibold)
      }

      Spacer()

      Text(workLogDraftStore.displayTime)
        .font(.system(.body, design: .monospaced))
        .fontWeight(.bold)
        .foregroundColor(.red)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color.systemBackground)
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    .onTapGesture {
      onTap()
    }
  }
}
