import SwiftUI

public struct RootView: View {
  @StateObject private var authState = AuthState()
  @StateObject private var activityState = ActivityState()
  @StateObject private var appState = AppState()
  @StateObject private var navigationState = NavigationState()
  @State private var selectedTab = 0

  public init() {}

  public var body: some View {
    Group {
      if authState.isLoading {
        ProgressView()
      }
      else if authState.isAuthenticated {
        mainContent
      }
      else {
        LoginView()
      }
    }
    .environmentObject(authState)
    .onAppear { authState.start() }
    .onDisappear { authState.stop() }
  }

  private var mainContent: some View {
    ZStack(alignment: .bottom) {
      TabView(selection: $selectedTab) {
        NavigationStack {
          ActivitiesView()
        }
        .tabItem {
          Label("Activities", systemImage: "clock")
        }
        .tag(0)

        NavigationStack {
          DomainsView()
        }
        .tabItem {
          Label("Domains", systemImage: "folder")
        }
        .tag(1)

        NavigationStack {
          ReportView()
        }
        .tabItem {
          Label("Reports", systemImage: "chart.bar.xaxis")
        }
        .tag(2)
      }
      .environmentObject(activityState)
      .environmentObject(appState)
      .environmentObject(navigationState)
      .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("navigateToActivities"))) { _ in
        selectedTab = 0
      }
      .onAppear {
        appState.start()
      }
      .onDisappear {
        appState.stop()
      }
      .background(Color(.systemGroupedBackground))

      if activityState.isRunning {
        TimerBanner {
          navigationState.isShowingActivityCreate = true
        }
        .environmentObject(activityState)
        .environmentObject(appState)
        .padding(.horizontal, 16)
        .padding(.bottom, 80)
      }
    }
    .sheet(isPresented: $navigationState.isShowingActivityCreate) {
      if let domainId = activityState.activeDomainId,
        let topicId = activityState.activeTopicId
      {
        ActivityCreateView(
          viewModel: ActivityCreateViewModel(
            domainId: domainId,
            topicId: topicId,
            activityState: activityState,
            appState: appState
          )
        )
        .environmentObject(activityState)
        .environmentObject(appState)
      }
    }
    .sheet(isPresented: $navigationState.isShowingSettings) {
      SettingsView()
    }
  }
}
