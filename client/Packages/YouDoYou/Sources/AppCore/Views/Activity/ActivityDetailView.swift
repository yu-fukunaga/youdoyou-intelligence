import SwiftUI

struct ActivityDetailView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var appState: AppState
  @StateObject var viewModel: ActivityDetailViewModel
  @State private var isShowingEdit = false

  private var durationText: String {
    let seconds = viewModel.activity.endedAt.timeIntervalSince(viewModel.activity.startedAt)
    let hours = Int(seconds) / 3600
    let minutes = Int(seconds) % 3600 / 60
    return "\(hours)h \(minutes)m"
  }

  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd (EEE) HH:mm"
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter.string(from: viewModel.activity.startedAt)
  }

  private var domain: Domain? {
    appState.domains.first { $0.id == viewModel.activity.domainId }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {

        // User
        HStack {
          Circle()
            .fill(Color(.systemGray5))
            .frame(width: 40, height: 40)
          VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.activity.userName)
              .font(.subheadline)
              .fontWeight(.medium)
            Text(formattedDate)
              .font(.caption)
              .foregroundColor(.secondary)
          }
          Spacer()
        }

        // Domain / Topic
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.blue)
            .offset(x: -3)
          VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
              RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .frame(width: 56, height: 56)
              VStack(alignment: .leading, spacing: 2) {
                Text(domain?.title ?? viewModel.activity.domainId)
                  .font(.caption)
                  .fontWeight(.bold)
                  .foregroundColor(.secondary)
                  .lineLimit(1)
                Text("Topic Title")
                  .font(.headline)
                  .lineLimit(2)
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

            Text(viewModel.activity.content)
              .font(.body)
              .foregroundColor(.primary)
          }
          .padding(16)
          .background(Color(.systemGroupedBackground))
          .cornerRadius(8)
        }

        Divider()

        // ボタン
        VStack(spacing: 12) {
          Button {
            isShowingEdit = true
          } label: {
            HStack {
              Image(systemName: "pencil")
              Text("編集")
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
          }

          Button {
            Task {
              await viewModel.delete()
            }
          } label: {
            HStack {
              Image(systemName: "trash")
              Text("削除")
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color(.systemGray5))
            .foregroundColor(.red)
            .cornerRadius(12)
          }
        }
      }
      .padding(20)
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("Activity")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: viewModel.isDeleted) {
      if viewModel.isDeleted {
        dismiss()
      }
    }
    .sheet(isPresented: $isShowingEdit) {
      ActivityEditView(viewModel: viewModel)
    }
  }
}
