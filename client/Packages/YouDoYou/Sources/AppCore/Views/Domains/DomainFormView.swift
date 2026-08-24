import PhotosUI
import SwiftUI
import UIKit

enum DomainFormMode {
  case create
  case edit(Domain)
}

private struct TopicField: Identifiable {
  let id: String
  var title = ""
  var existingImageUrl: String?
  var imageData: Data?
}

struct DomainFormView: View {
  @Environment(\.dismiss) var dismiss
  private let domainRepo = DomainRepository()
  private let mode: DomainFormMode

  @State private var title = ""
  @State private var description = ""
  @State private var topicFields: [TopicField] = []
  @State private var color: Color = .blue
  @State private var isLoading = false
  @State private var error: String?

  init(mode: DomainFormMode) {
    self.mode = mode
    switch mode {
    case .create:
      break
    case .edit(let domain):
      _title = State(initialValue: domain.title)
      _description = State(initialValue: domain.description)
      _color = State(initialValue: domain.color.flatMap(Color.init(hex:)) ?? .blue)
      _topicFields = State(
        initialValue: domain.topics.map {
          TopicField(id: $0.id, title: $0.title, existingImageUrl: $0.imageUrl)
        })
    }
  }

  private var headerTitle: String {
    switch mode {
    case .create: return "New Domain"
    case .edit: return "Edit Domain"
    }
  }

  private var actionLabel: String {
    switch mode {
    case .create: return "Create"
    case .edit: return "Save"
    }
  }

  var isValid: Bool {
    !title.isEmpty
  }

  private func submit() async {
    isLoading = true
    error = nil
    do {
      var topics: [Topic] = []
      for field in topicFields where !field.title.isEmpty {
        var imageUrl = field.existingImageUrl
        if let imageData = field.imageData {
          imageUrl = try await domainRepo.uploadTopicImage(topicId: field.id, data: imageData)
        }
        topics.append(Topic(id: field.id, title: field.title, imageUrl: imageUrl))
      }
      switch mode {
      case .create:
        try await domainRepo.create(
          title: title,
          description: description,
          topics: topics,
          color: color.hexString
        )
      case .edit(var domain):
        domain.title = title
        domain.description = description
        domain.topics = topics
        domain.color = color.hexString
        try await domainRepo.update(domain)
      }
      dismiss()
    }
    catch {
      self.error = error.localizedDescription
    }
    isLoading = false
  }

  var body: some View {
    VStack(spacing: 0) {
      DomainFormHeaderView(
        title: headerTitle,
        actionLabel: actionLabel,
        isActionDisabled: !isValid || isLoading,
        onClose: { dismiss() },
        onAction: { Task { await submit() } }
      )

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          DomainColorAndNameSectionView(color: $color, title: $title)

          DomainDescriptionSectionView(description: $description)

          DomainTopicsSectionView(topicFields: $topicFields)

          // エラー
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
    }
    .background(Color(.systemGroupedBackground))
  }
}

private struct DomainFormHeaderView: View {
  let title: String
  let actionLabel: String
  let isActionDisabled: Bool
  let onClose: () -> Void
  let onAction: () -> Void

  var body: some View {
    HStack {
      Button(action: onClose) {
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(.secondary)
          .font(.title2)
      }
      Spacer()
      Text(title)
        .font(.headline)
        .fontWeight(.semibold)
      Spacer()
      Button(actionLabel, action: onAction)
        .fontWeight(.semibold)
        .disabled(isActionDisabled)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
  }
}

private struct DomainColorAndNameSectionView: View {
  @Binding var color: Color
  @Binding var title: String

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      VStack(spacing: 8) {
        ColorPicker("", selection: $color)
          .labelsHidden()
          .frame(width: 44, height: 44)
        Text("COLOR")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)
      }

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
  }
}

private struct DomainDescriptionSectionView: View {
  @Binding var description: String

  var body: some View {
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
  }
}

private struct DomainTopicsSectionView: View {
  @Binding var topicFields: [TopicField]

  var body: some View {
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
          TopicFieldRow(
            field: $field,
            onRemove: { topicFields.removeAll { $0.id == field.id } }
          )
        }

        // Add Topic ボタン
        Button {
          topicFields.append(TopicField(id: UUID().uuidString))
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
  }
}

private struct TopicFieldRow: View {
  @Binding var field: TopicField
  let onRemove: () -> Void
  @State private var pickerItem: PhotosPickerItem?

  var body: some View {
    HStack(spacing: 12) {
      PhotosPicker(selection: $pickerItem, matching: .images) {
        Group {
          if let imageData = field.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
              .resizable()
              .scaledToFill()
          }
          else if let urlString = field.existingImageUrl, let url = URL(string: urlString), !urlString.isEmpty {
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
      }
      .buttonStyle(.plain)
      .onChange(of: pickerItem) { _, newValue in
        Task {
          field.imageData = try? await newValue?.loadTransferable(type: Data.self)
        }
      }

      TextField("Topic Title (e.g., Infrastructure)", text: $field.title)

      Button(action: onRemove) {
        Image(systemName: "trash")
          .foregroundColor(.secondary)
      }
    }
    .padding(12)
    .background(Color(.systemBackground))
    .cornerRadius(12)
  }
}
