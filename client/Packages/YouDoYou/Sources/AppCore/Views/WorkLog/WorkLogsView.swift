import SwiftUI

struct WorkLogsView: View {
  @StateObject private var viewModel = WorkLogViewModel()

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        Text("Today")
          .font(.title2)
          .fontWeight(.bold)
          .padding(.horizontal)

        ForEach(viewModel.todayWorkLogs) { workLog in
          WorkLogCard(workLog: workLog)
        }

        Text("Recent WorkLog")
          .font(.title2)
          .fontWeight(.bold)
          .padding(.horizontal)

        ForEach(viewModel.pastWorkLogs) { workLog in
          WorkLogCard(workLog: workLog)
        }
      }
      .padding(16)
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        UserIconButton()
      }
    }
    .onAppear {
      viewModel.startObserving()
    }
    .onDisappear {
      viewModel.stopObserving()
    }
    .background(Color(.systemGroupedBackground))
  }
}
