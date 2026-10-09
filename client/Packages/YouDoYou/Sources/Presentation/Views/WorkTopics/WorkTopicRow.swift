import Domain
import SwiftUI

struct WorkTopicRow: View {
  let workTopic: WorkTopic
  let onStart: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onStart) {
        HStack(spacing: 12) {
          thumbnail
            .frame(width: 56, height: 56)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))

          Text(workTopic.title)
            .font(.body)
            .fontWeight(.medium)
            .lineLimit(2)
            .foregroundColor(.primary)

          Spacer(minLength: 8)
        }
      }
      .buttonStyle(.plain)

      Menu {
        Button("編集", systemImage: "pencil") { onEdit() }
        Button("削除", systemImage: "trash", role: .destructive) { onDelete() }
      } label: {
        Image(systemName: "ellipsis")
          .font(.body)
          .foregroundColor(.secondary)
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
    }
    .padding(12)
    .background(Color.systemBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  @ViewBuilder
  private var thumbnail: some View {
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

#Preview {
  WorkTopicRow(
    workTopic: WorkTopic(
      title: "YouDoYou Intelligence開発",
      imageUrl: "https://picsum.photos/seed/topic-001-1/200/200"
    ),
    onStart: {},
    onEdit: {},
    onDelete: {}
  )
  .padding()
}
