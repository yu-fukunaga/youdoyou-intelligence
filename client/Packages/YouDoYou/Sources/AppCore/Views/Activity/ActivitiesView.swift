import SwiftUI

struct ActivitiesView: View {
  @StateObject private var viewModel = ActivityViewModel()

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 24) {
        Text("Today")
          .font(.title2)
          .fontWeight(.bold)
          .padding(.horizontal)

        ForEach(viewModel.todayActivities) { activity in
          ActivityCard(activity: activity)
        }

        Text("Recent Activity")
          .font(.title2)
          .fontWeight(.bold)
          .padding(.horizontal)

        ForEach(viewModel.pastActivities) { activity in
          ActivityCard(activity: activity)
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
