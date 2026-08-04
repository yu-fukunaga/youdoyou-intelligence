import SwiftUI

struct ActivityCard: View {
  @EnvironmentObject var appState: AppState
  let activity: Activity

  private var durationText: String {
    let seconds = activity.endedAt.timeIntervalSince(activity.startedAt)
    let hours = Int(seconds) / 3600
    let minutes = Int(seconds) % 3600 / 60
    return "\(hours)h \(minutes)m"
  }

  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd (EEE) HH:mm"
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter.string(from: activity.startedAt)
  }

  var body: some View {

    NavigationLink(
      destination: ActivityDetailView(
        viewModel: ActivityDetailViewModel(activity: activity, appState: appState)
      )
    ) {
      VStack(alignment: .leading, spacing: 12) {
        // User
        HStack {
          if let url = URL(string: activity.userIcon), !activity.userIcon.isEmpty {
            AsyncImage(url: url) { image in
              image
                .resizable()
                .scaledToFill()
            } placeholder: {
              Circle()
                .fill(Color(.systemGray5))
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
          }
          else {
            Circle()
              .fill(Color(.systemGray5))
              .frame(width: 32, height: 32)
          }
          VStack(alignment: .leading, spacing: 2) {
            Text(activity.userName)
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
              // Topic + Domain情報
              HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                  .fill(Color(.systemGray5))
                  .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                  Text("Domain Title Domain Title Domain Title")  // 後でappStateから
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                  Text("Topic Title")  // 後でappStateから
                    .font(.headline)
                    .lineLimit(2)
                    .frame(height: 44, alignment: .top)
                }
                Spacer()
                HStack(spacing: 4) {
                  Image(systemName: "clock")
                    .font(.caption2)
                  Text(durationText)
                    .font(.caption)
                }
                .foregroundColor(.secondary)
              }

              Text(activity.content)
                .font(.body)
                .foregroundColor(.primary)
            }
          }
          .padding(16)
          .background(Color(.systemGroupedBackground))
          .cornerRadius(8)
        }

      }
      .padding()
      .background(Color(.systemBackground))
      .cornerRadius(12)
      .shadow(radius: 1)
    }
    .buttonStyle(.plain)
  }
}
