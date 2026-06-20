import SwiftUI

struct DomainItem: View {
  let domain: Domain

  var body: some View {
    VStack {
      // ------------------------------
      // Domain Title
      // ------------------------------
      NavigationLink(destination: DomainDetailView(domain: domain)) {
        HStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 32, height: 32)
          Text(domain.title)
          Spacer()
          Image(systemName: "chevron.right")
            .foregroundColor(.secondary)
            .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
      }
      .buttonStyle(.plain)

      // ------------------------------
      // Topics
      // ------------------------------
      ScrollView(.horizontal) {
        HStack {
          ForEach(domain.topics) { topic in
            TopicCard(topic: topic, domain: domain)
          }
        }
      }
    }
    .padding(.vertical, 24)
  }
}

struct TopicCard: View {
  let topic: Topic
  let domain: Domain
  @EnvironmentObject var activityState: ActivityState
  @EnvironmentObject var appState: AppState

  private var isDisabled: Bool {
    activityState.startDate != nil && activityState.activeTopicId != topic.id
  }
  @State private var isShowingCreateView = false

  var body: some View {
    Button {
      isShowingCreateView = true
    } label: {
      VStack(alignment: .leading, spacing: 6) {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(.systemGray5))
          .frame(width: 32, height: 32)
        Text(topic.title)
          .font(.subheadline)
          .fontWeight(.medium)
          .lineLimit(2)
          .frame(height: 44)
        HStack(spacing: 6) {
          Text("START WORK")
            .font(.caption2)
            .foregroundColor(.secondary)
          Image(systemName: "chevron.right")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
      }
      .opacity(isDisabled ? 0.4 : 1.0)
      .padding(16)
      .frame(width: 140, height: 140, alignment: .leading)
      .background(Color.white)
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .disabled(isDisabled)
    .buttonStyle(.plain)
    .sheet(isPresented: $isShowingCreateView) {
      ActivityCreateView(
        viewModel: ActivityCreateViewModel(
          domainId: domain.id ?? "",
          topicId: topic.id,
          activityState: activityState,
          appState: appState
        )
      )
      .environmentObject(activityState)
      .environmentObject(appState)
      .presentationCornerRadius(16)
    }
  }
}
