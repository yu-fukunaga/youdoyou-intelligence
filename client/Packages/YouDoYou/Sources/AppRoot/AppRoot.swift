import Domain
import Infrastructure
import Presentation
import SwiftUI

public struct RootView: View {
  @StateObject private var authState = AuthState(repository: AuthRepository())
  @State private var workLogDraftStore = WorkLogDraftStore(
    repository: WorkLogRepository(),
    authRepository: AuthRepository()
  )
  @StateObject private var appState = AppState(workTopicRepository: WorkTopicRepository())
  @State private var workLogRepository = WorkLogRepository()
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
          HomeView(workLogRepository: workLogRepository)
        }
        .tabItem {
          Label("Home", systemImage: "house")
        }
        .tag(0)

        NavigationStack {
          ReportView(repository: workLogRepository)
        }
        .tabItem {
          Label("Reports", systemImage: "chart.bar.xaxis")
        }
        .tag(1)
      }
      .environment(workLogDraftStore)
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
      .background(Color.systemGroupedBackground)

      if workLogDraftStore.isRunning {
        TimerBanner {
          navigationState.isShowingWorkLogCreate = true
        }
        .environment(workLogDraftStore)
        .environmentObject(appState)
        .padding(.horizontal, 16)
        .padding(.bottom, 80)
      }
    }
    .sheet(isPresented: $navigationState.isShowingWorkLogCreate) {
      if let workTopicId = workLogDraftStore.activeWorkTopicId {
        WorkLogCreateView(workTopicId: workTopicId)
          .environment(workLogDraftStore)
          .environmentObject(appState)
      }
    }
    .sheet(isPresented: $navigationState.isShowingSettings) {
      SettingsView()
    }
  }
}
