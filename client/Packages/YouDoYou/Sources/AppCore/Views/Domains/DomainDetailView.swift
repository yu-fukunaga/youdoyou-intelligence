import SwiftUI

struct DomainDetailView: View {
  @Environment(WorkLogDraftStore.self) var workLogDraftStore: WorkLogDraftStore
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) var dismiss
  let domain: Domain

  private let domainRepo = DomainRepository()
  @State private var isShowingEdit = false
  @State private var isShowingDeleteConfirmation = false
  @State private var error: String?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        HStack(spacing: 16) {
          RoundedRectangle(cornerRadius: 12)
            .fill(domain.color.flatMap(Color.init(hex:)) ?? Color(.systemGray5))
            .frame(width: 64, height: 64)

          if !domain.description.isEmpty {
            Text(domain.description)
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("TOPICS")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)

          VStack(spacing: 8) {
            ForEach(domain.topics) { topic in
              DomainDetailTopicRow(domain: domain, topic: topic)
            }
          }
        }

        if let error {
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
    .background(Color(.systemGroupedBackground))
    .navigationTitle(domain.title)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Button {
            isShowingEdit = true
          } label: {
            Label("Edit", systemImage: "pencil")
          }
          Button(role: .destructive) {
            isShowingDeleteConfirmation = true
          } label: {
            Label("Delete", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .sheet(isPresented: $isShowingEdit) {
      DomainFormView(mode: .edit(domain))
    }
    .alert("Domainを削除しますか？", isPresented: $isShowingDeleteConfirmation) {
      Button("キャンセル", role: .cancel) {}
      Button("削除", role: .destructive) {
        Task {
          do {
            try await domainRepo.delete(id: domain.id ?? "")
            dismiss()
          }
          catch {
            self.error = error.localizedDescription
          }
        }
      }
    } message: {
      Text("この操作は取り消せません")
    }
  }
}

private struct DomainDetailTopicRow: View {
  let domain: Domain
  let topic: Topic
  @Environment(WorkLogDraftStore.self) var workLogDraftStore: WorkLogDraftStore
  @EnvironmentObject var appState: AppState
  @State private var isShowingCreateView = false

  private var isDisabled: Bool {
    workLogDraftStore.startDate != nil && workLogDraftStore.activeTopicId != topic.id
  }

  var body: some View {
    Button {
      isShowingCreateView = true
    } label: {
      HStack(spacing: 12) {
        Group {
          if let urlString = topic.imageUrl, let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { image in
              image
                .resizable()
                .scaledToFill()
            } placeholder: {
              Color(.systemGray5)
            }
          }
          else {
            Color(.systemGray5)
          }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        Text(topic.title)
          .foregroundColor(.primary)

        Spacer()

        Text("START WORK")
          .font(.caption2)
          .foregroundColor(.secondary)
        Image(systemName: "chevron.right")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
      .opacity(isDisabled ? 0.4 : 1.0)
      .padding(12)
      .background(Color(.systemBackground))
      .cornerRadius(12)
    }
    .disabled(isDisabled)
    .buttonStyle(.plain)
    .sheet(isPresented: $isShowingCreateView) {
      WorkLogCreateView(domainId: domain.id ?? "", topicId: topic.id)
        .environment(workLogDraftStore)
        .environmentObject(appState)
        .presentationCornerRadius(16)
    }
  }
}
