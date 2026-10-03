import Domain
import SwiftUI

struct WorkLogsView: View {
  @StateObject private var viewModel: WorkLogViewModel
  private let repository: any WorkLogRepositoryProtocol

  init(repository: any WorkLogRepositoryProtocol) {
    self.repository = repository
    _viewModel = StateObject(wrappedValue: WorkLogViewModel(repository: repository))
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        Text("Today")
          .font(.title2)
          .fontWeight(.bold)
          .padding(.horizontal)

        ForEach(viewModel.todayWorkLogs) { workLog in
          WorkLogCard(workLog: workLog, repository: repository)
        }

        Text("Recent WorkLog")
          .font(.title2)
          .fontWeight(.bold)
          .padding(.horizontal)

        ForEach(viewModel.pastWorkLogs) { workLog in
          WorkLogCard(workLog: workLog, repository: repository)
        }
      }
      .padding(16)
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        UserIconButton()
      }
    }
    .onAppear {
      viewModel.startObserving()
    }
    .onDisappear {
      viewModel.stopObserving()
    }
    .background(Color.systemGroupedBackground)
  }
}
