import SwiftUI
import YouDoYouFirestore

private struct TopicField: Identifiable {
  let id = UUID()
  var title = ""
}

struct DomainCreateView: View {
  @Environment(\.dismiss) var dismiss
  @StateObject private var viewModel = DomainCreateViewModel()
  @State private var title = ""
  @State private var description = ""
  @State private var topicFields: [TopicField] = [TopicField()]

  var isValid: Bool {
    !title.isEmpty && topicFields.contains(where: { !$0.title.isEmpty })
  }

  var body: some View {
    VStack(spacing: 0) {
      // ヘッダー
      HStack {
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
            .font(.title2)
        }
        Spacer()
        Text("New Domain")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
        Button("Create") {
          Task {
            await viewModel.createDomain(
              title: title,
              description: description,
              topicTitles: topicFields.map(\.title).filter { !$0.isEmpty }
            )
            if viewModel.error == nil {
              dismiss()
            }
          }
        }
        .fontWeight(.semibold)
        .disabled(!isValid || viewModel.isLoading)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {

          HStack(alignment: .top, spacing: 16) {
            // Domain Icon
            VStack(spacing: 8) {
              ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 20)
                  .fill(Color(.systemGray5))
                  .frame(width: 100, height: 100)
                Circle()
                  .fill(Color(.systemBackground))
                  .frame(width: 28, height: 28)
                  .overlay(
                    Image(systemName: "pencil")
                      .font(.caption)
                      .foregroundColor(.primary)
                  )
              }
              Text("ICON")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            }

            // Domain Name
            VStack(alignment: .leading, spacing: 8) {
              Text("DOMAIN NAME")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
              TextField("Enter domain name...", text: $title)
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .frame(maxWidth: .infinity)

          }

          // Description
          VStack(alignment: .leading, spacing: 8) {
            Text("DESCRIPTION")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.secondary)
            TextField("Briefly describe the vision of this domain...", text: $description, axis: .vertical)
              .lineLimit(4...8)
              .padding(16)
              .background(Color(.systemBackground))
              .cornerRadius(12)
          }

          // Topics
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("TOPICS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
              Spacer()
              Text("\(topicFields.filter { !$0.title.isEmpty }.count) Topics Created")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
              ForEach($topicFields) { $field in
                HStack(spacing: 12) {
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                  TextField("Topic Title (e.g., Infrastructure)", text: $field.title)
                  Button {
                    topicFields.removeAll { $0.id == field.id }
                  } label: {
                    Image(systemName: "trash")
                      .foregroundColor(.secondary)
                  }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
              }

              // Add Topic ボタン
              Button {
                topicFields.append(TopicField())
              } label: {
                HStack {
                  Image(systemName: "plus.circle")
                  Text("Add Topic")
                    .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .foregroundColor(.primary)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundColor(.secondary)
                )
              }
            }
          }

          // エラー
          if let error = viewModel.error {
            HStack(spacing: 8) {
              Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
              Text(error)
                .font(.caption)
                .foregroundColor(.red)
            }
          }
        }
        .padding(20)
      }
    }
    .background(Color(.systemGroupedBackground))
  }
}
