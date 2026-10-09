import Domain

#if os(iOS)
  import PhotosUI
  import SwiftUI
  import UIKit

  public enum WorkTopicFormMode {
    case create
    case edit(WorkTopic)
  }

  public struct WorkTopicFormView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    public let mode: WorkTopicFormMode

    @State private var title = ""
    @State private var description = ""
    @State private var imageData: Data?
    @State private var existingImageUrl: String?
    @State private var pickerItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var error: String?

    private let workTopicId: String

    public init(mode: WorkTopicFormMode) {
      self.mode = mode
      switch mode {
      case .create:
        workTopicId = UUID.v7().uuidString
      case .edit(let workTopic):
        workTopicId = workTopic.id
        _title = State(initialValue: workTopic.title)
        _description = State(initialValue: workTopic.description ?? "")
        _existingImageUrl = State(initialValue: workTopic.imageUrl)
      }
    }

    private var headerTitle: String {
      switch mode {
      case .create: return "New Topic"
      case .edit: return "Edit Topic"
      }
    }

    private var actionLabel: String {
      switch mode {
      case .create: return "Create"
      case .edit: return "Save"
      }
    }

    private var isValid: Bool {
      !title.isEmpty
    }

    private func submit() async {
      isLoading = true
      error = nil
      do {
        var imageUrl = existingImageUrl
        if let imageData {
          imageUrl = try await appState.workTopicRepository.uploadImage(workTopicId: workTopicId, data: imageData)
        }
        let trimmedDescription = description.isEmpty ? nil : description

        switch mode {
        case .create:
          let newWorkTopic = WorkTopic(
            id: workTopicId,
            title: title,
            description: trimmedDescription,
            imageUrl: imageUrl
          )
          try await appState.workTopicRepository.add(newWorkTopic)
        case .edit(var workTopic):
          workTopic.title = title
          workTopic.description = trimmedDescription
          workTopic.imageUrl = imageUrl
          try await appState.workTopicRepository.update(workTopic)
        }
        dismiss()
      }
      catch {
        self.error = error.localizedDescription
      }
      isLoading = false
    }

    public var body: some View {
      VStack(spacing: 0) {
        header

        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            imageSection
            nameSection
            descriptionSection

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
      .background(Color.systemGroupedBackground)
    }

    private var header: some View {
      HStack {
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
            .font(.title2)
        }
        Spacer()
        Text(headerTitle)
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
        Button(actionLabel) {
          Task { await submit() }
        }
        .fontWeight(.semibold)
        .disabled(!isValid || isLoading)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
    }

    private var imageSection: some View {
      VStack(alignment: .leading, spacing: 8) {
        Text("IMAGE")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)

        PhotosPicker(selection: $pickerItem, matching: .images) {
          thumbnail
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .bottomTrailing) {
              Image(systemName: "pencil.circle.fill")
                .font(.title3)
                .foregroundStyle(.white, Color.blue)
                .padding(4)
            }
        }
        .buttonStyle(.plain)
        .onChange(of: pickerItem) { _, newValue in
          Task {
            imageData = try? await newValue?.loadTransferable(type: Data.self)
          }
        }
      }
    }

    @ViewBuilder
    private var thumbnail: some View {
      if let imageData, let uiImage = UIImage(data: imageData) {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFill()
      }
      else if let urlString = existingImageUrl, let url = URL(string: urlString), !urlString.isEmpty {
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

    private var nameSection: some View {
      VStack(alignment: .leading, spacing: 8) {
        Text("NAME")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)
        TextField("Enter topic name...", text: $title)
          .padding(16)
          .background(Color.systemBackground)
          .cornerRadius(12)
      }
    }

    private var descriptionSection: some View {
      VStack(alignment: .leading, spacing: 8) {
        Text("DESCRIPTION")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)
        TextField("Briefly describe this topic...", text: $description, axis: .vertical)
          .lineLimit(4...8)
          .padding(16)
          .background(Color.systemBackground)
          .cornerRadius(12)
      }
    }
  }

  #Preview {
    WorkTopicFormView(mode: .create)
  }
#endif
