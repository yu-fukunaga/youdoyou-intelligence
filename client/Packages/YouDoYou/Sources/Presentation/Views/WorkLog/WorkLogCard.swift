import Domain
import SwiftUI

struct WorkLogCard: View {
  @EnvironmentObject var appState: AppState
  let workLog: WorkLog
  let repository: any WorkLogRepositoryProtocol

  private var durationText: String {
    let seconds = workLog.endedAt.timeIntervalSince(workLog.startedAt)
    let hours = Int(seconds) / 3600
    let minutes = Int(seconds) % 3600 / 60
    return "\(hours)h \(minutes)m"
  }

  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd (EEE) HH:mm"
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter.string(from: workLog.startedAt)
  }

  private var workTopic: WorkTopic? {
    appState.workTopics.first { $0.id == workLog.workTopicId }
  }

  var body: some View {

    NavigationLink(
      destination: WorkLogDetailView(
        viewModel: WorkLogDetailViewModel(
          workLog: workLog, appState: appState, repository: repository)
      )
    ) {
      VStack(alignment: .leading, spacing: 12) {
        // User
        HStack {
          if let url = URL(string: workLog.userIcon), !workLog.userIcon.isEmpty {
            AsyncImage(url: url) { image in
              image
                .resizable()
                .scaledToFill()
            } placeholder: {
              Circle()
                .fill(Color.systemGray5)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
          }
          else {
            Circle()
              .fill(Color.systemGray5)
              .frame(width: 32, height: 32)
          }
          VStack(alignment: .leading, spacing: 2) {
            Text(workLog.userName)
              .font(.subheadline)
              .fontWeight(.medium)
            Text(formattedDate)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Spacer()
          Image(systemName: "chevron.right")
            .foregroundColor(.secondary)
            .font(.caption)
        }

        // Contents
        ZStack(alignment: .leading) {
          // 後ろのカラーカード
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.blue)
            .offset(x: -3)
          // 前のカード
          HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 16) {
              // WorkTopic
              HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                  .fill(Color.systemGray5)
                  .frame(width: 56, height: 56)
                Text(workTopic?.title ?? workLog.workTopicId)
                  .font(.headline)
                  .lineLimit(2)
                  .frame(height: 44, alignment: .top)
                Spacer()
                HStack(spacing: 4) {
                  Image(systemName: "clock")
                    .font(.caption2)
                  Text(durationText)
                    .font(.caption)
                }
                .foregroundColor(.secondary)
              }

              Text(workLog.content)
                .font(.body)
                .foregroundColor(.primary)
            }
          }
          .padding(16)
          .background(Color.systemGroupedBackground)
          .cornerRadius(8)
        }

      }
      .padding()
      .background(Color.systemBackground)
      .cornerRadius(12)
      .shadow(radius: 1)
    }
    .buttonStyle(.plain)
  }
}
