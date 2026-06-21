import SwiftUI

struct DomainsView: View {
  @EnvironmentObject var appState: AppState
  @State private var isShowingCreate = false

  var body: some View {
    ZStack(alignment: .bottomTrailing) {

      ScrollView {
        LazyVStack {
          ForEach(appState.domains) { domain in
            DomainItem(domain: domain)
          }
        }
      }
      .navigationTitle("Domains")
      .navigationBarTitleDisplayMode(.large)
      .toolbarBackground(.hidden, for: .navigationBar)
      .background(Color(.systemGroupedBackground))
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
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
      DomainCreateView()
    }
  }

}
