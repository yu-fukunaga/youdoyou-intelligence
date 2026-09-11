import SwiftUI

struct DomainsView: View {
  @EnvironmentObject private var appState: AppState
  @State private var isShowingCreate = false

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      ScrollView {
        LazyVStack {
          ForEach(appState.domains) { domain in
            DomainCard(domain: domain)
          }
        }
      }
      .navigationTitle("Domains")
      .toolbarTitleDisplayMode(.automatic)
      #if os(iOS)
        .toolbarBackground(.hidden, for: .navigationBar)
      #endif
      .background(Color.systemGroupedBackground)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          UserIconButton()
        }
      }
      Button {
        isShowingCreate = true
      } label: {
        Image(systemName: "plus")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.white)
          .frame(width: 56, height: 56)
          .background(Color.blue)
          .clipShape(Circle())
          .shadow(radius: 4)
      }
      .padding(24)
    }
    .sheet(isPresented: $isShowingCreate) {
      #if os(iOS)
        DomainFormView(mode: .create)
      #endif
    }
  }
}

private struct DomainCard: View {
  let domain: Domain

  var body: some View {
    NavigationLink(destination: DomainDetailView(domain: domain)) {
      HStack(alignment: .top, spacing: 12) {
        RoundedRectangle(cornerRadius: 8)
          .fill(domain.color.flatMap(Color.init(hex:)) ?? Color.systemGray5)
          .frame(width: 80, height: 80)
        VStack {
          Text(domain.title)
        }
        Spacer()
      }
      .padding()
      .background(Color.systemBackground)
      .cornerRadius(12)
      .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    .buttonStyle(.plain)
  }
}
