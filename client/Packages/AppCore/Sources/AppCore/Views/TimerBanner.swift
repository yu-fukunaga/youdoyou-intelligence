import SwiftUI

struct TimerBanner: View {
  @EnvironmentObject var activityState: ActivityState
  @EnvironmentObject var appState: AppState
  var onTap: () -> Void

  private var domain: Domain? {
    appState.domains.first { $0.id == activityState.activeDomainId }
  }

  private var topic: Topic? {
    domain?.topics.first { $0.id == activityState.activeTopicId }
  }

  var body: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(Color.red)
        .frame(width: 8, height: 8)

      VStack(alignment: .leading, spacing: 2) {
        Text(domain?.title ?? "")
          .font(.caption)
          .foregroundColor(.secondary)
        Text(topic?.title ?? "")
          .font(.subheadline)
          .fontWeight(.semibold)
      }

      Spacer()

      Text(activityState.displayTime)
        .font(.system(.body, design: .monospaced))
        .fontWeight(.bold)
        .foregroundColor(.red)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    .onTapGesture {
      onTap()
    }
  }
}
