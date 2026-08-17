import SwiftUI

public struct RootView: View {
  @StateObject private var authState = AuthState()
  @StateObject private var workLogState = WorkLogState()
  @State private var workLogStore = WorkLogStore(repository: WorkLogRepository())
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
          HomeView()
        }
        .tabItem {
          Label("Home", systemImage: "house")
        }
        .tag(0)

        NavigationStack {
          ReportView()
        }
        .tabItem {
          Label("Reports", systemImage: "chart.bar.xaxis")
        }
        .tag(1)
      }
      .environmentObject(workLogState)
      .environment(workLogStore)
      .environmentObject(appState)
      .environmentObject(navigationState)
      .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("navigateToWorkLogs"))) { _ in
        selectedTab = 0
      }
      .onAppear {
        appState.start()
      }
      .onDisappear {
        appState.stop()
      }
      .background(Color(.systemGroupedBackground))

      if workLogState.isRunning {
        TimerBanner {
          navigationState.isShowingWorkLogCreate = true
        }
        .environmentObject(workLogState)
        .environmentObject(appState)
        .padding(.horizontal, 16)
        .padding(.bottom, 80)
      }
    }
    .sheet(isPresented: $navigationState.isShowingWorkLogCreate) {
      if let domainId = workLogState.activeDomainId,
        let topicId = workLogState.activeTopicId
      {
        WorkLogCreateView(
          viewModel: WorkLogCreateViewModel(
            domainId: domainId,
            topicId: topicId,
            workLogState: workLogState,
            appState: appState
          ),
          domainId: domainId,
          topicId: topicId
        )
        .environmentObject(workLogState)
        .environmentObject(appState)
      }
    }
    .sheet(isPresented: $navigationState.isShowingSettings) {
      SettingsView()
    }
  }
}
