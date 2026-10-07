import Domain
import SwiftUI

public struct DomainItem: View {
  public let domain: WorkTheme

  public init(domain: WorkTheme) {
    self.domain = domain
  }

  public var body: some View {
    VStack {
      // ------------------------------
      // Domain Title
      // ------------------------------
      NavigationLink(destination: DomainDetailView(domain: domain)) {
        HStack {
          Circle()
            .fill(domain.color.flatMap(Color.init(hex:)) ?? Color.systemGray5)
            .frame(width: 12, height: 12)
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

public struct TopicCard: View {
  public let topic: Topic
  public let domain: WorkTheme

  public init(topic: Topic, domain: WorkTheme) {
    self.topic = topic
    self.domain = domain
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Group {
        if let urlString = topic.imageUrl, let url = URL(string: urlString), !urlString.isEmpty {
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
      .frame(width: 32, height: 32)
      .clipShape(RoundedRectangle(cornerRadius: 8))
      Text(topic.title)
        .font(.subheadline)
        .fontWeight(.medium)
        .lineLimit(2)
        .frame(height: 44)
    }
    .padding(16)
    .frame(width: 140, height: 140, alignment: .leading)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}
