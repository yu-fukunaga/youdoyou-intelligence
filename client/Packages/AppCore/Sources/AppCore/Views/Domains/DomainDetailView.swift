import SwiftUI

struct DomainDetailView: View {
  let domain: Domain

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(domain.title)
      Text(domain.description)
      Text("Topics: \(domain.topics.count)")
    }
    .padding()
    .navigationTitle(domain.title)
  }
}
