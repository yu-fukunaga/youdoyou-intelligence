import SwiftUI

struct WorkLogCreateView: View {
  @Environment(\.dismiss) var dismiss
  @Environment(WorkLogDraftStore.self) var workLogDraftStore: WorkLogDraftStore
  @EnvironmentObject var appState: AppState
  @State private var showCancelConfirmation = false
  @State private var isLoading = false
  @State private var error: String?

  let domainId: String
  let topicId: String

  private var domain: Domain? {
    appState.domains.first { $0.id == domainId }
  }

  private var topic: Topic? {
    domain?.topics.first { $0.id == topicId }
  }

  var body: some View {
    VStack(spacing: 0) {

      WorkLogHeaderView(
        isReadyToPost: workLogDraftStore.isReadyToPost,
        onShowCancelConfirmation: { showCancelConfirmation = true },
        onClose: { dismiss() }
      )

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {

          WorkLogDomainTopicView(
            domainTitle: domain?.title ?? "",
            topicTitle: topic?.title ?? ""
          )

          WorkLogTimeSectionView(
            workLogDraftStore: workLogDraftStore,
            onStartTimer: {
              workLogDraftStore.startTimer(
                domainId: domainId,
                topicId: topicId,
                domainTitle: domain?.title ?? "",
                topicTitle: topic?.title ?? ""
              )
            },
            onStopTimer: { workLogDraftStore.stopTimer() }
          )

          // 内容
          WorkLogContentSectionView(
            content: Binding(
              get: { workLogDraftStore.content },
              set: { workLogDraftStore.content = $0 }
            )
          )

          // エラー
          if let error = error {
            HStack(spacing: 8) {
              Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
              Text(error)
                .font(.caption)
                .foregroundColor(.red)
            }
          }

          // Postボタン
          Button {
            Task {
              isLoading = true
              defer { isLoading = false }
              do {
                try await workLogDraftStore.post()
                dismiss()
                NotificationCenter.default.post(name: NSNotification.Name("navigateToWorkLogs"), object: nil)
              }
              catch {
                self.error = error.localizedDescription
              }
            }
          } label: {
            Text("Post")
              .fontWeight(.semibold)
              .frame(maxWidth: .infinity)
              .padding(14)
              .background(workLogDraftStore.isReadyToPost ? Color.blue : Color.gray)
              .foregroundColor(.white)
              .cornerRadius(12)
          }
          .disabled(!workLogDraftStore.isReadyToPost || isLoading)

          Button {
            if workLogDraftStore.isReadyToPost || workLogDraftStore.isRunning {
              showCancelConfirmation = true
            }
            else {
              dismiss()
            }
          } label: {
            Text("Cancel")
              .fontWeight(.semibold)
              .frame(maxWidth: .infinity)
              .padding(14)
              .background(Color(.systemGray5))
              .foregroundColor(.primary)
              .cornerRadius(12)
          }

        }
        .padding(20)
      }
    }
    .background(Color(.systemGroupedBackground))
    .interactiveDismissDisabled(workLogDraftStore.isReadyToPost)
    .onAppear {
      if !workLogDraftStore.isRunning && !workLogDraftStore.isReadyToPost {
        let now = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970))
        workLogDraftStore.startDate = now
        workLogDraftStore.endDate = now
      }
    }
    .onDisappear {
      if !workLogDraftStore.isReadyToPost && !workLogDraftStore.isRunning {
        workLogDraftStore.reset()
      }
    }
    .alert("入力を破棄しますか？", isPresented: $showCancelConfirmation) {
      Button("キャンセル", role: .cancel) {}
      Button("破棄して閉じる", role: .destructive) {
        workLogDraftStore.reset()
        dismiss()
      }
    } message: {
      Text("入力中のデータが失われます")
    }
  }
}

private func calculateDuration(from: Date, to: Date) -> String {
  let elapsed = Int(to.timeIntervalSince(from))
  let hours = elapsed / 3600
  let minutes = (elapsed % 3600) / 60
  let seconds = elapsed % 60
  return String(format: "%d:%02d:%02d", hours, minutes, seconds)
}

private struct WorkLogHeaderView: View {
  let isReadyToPost: Bool
  let onShowCancelConfirmation: () -> Void
  let onClose: () -> Void
  var body: some View {
    HStack {
      Button {
        if isReadyToPost {
          onShowCancelConfirmation()
        }
        else {
          onClose()
        }
      } label: {
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(.secondary)
          .font(.title2)
      }
      Spacer()
      Text("作業を記録")
        .font(.headline)
        .fontWeight(.semibold)
      Spacer()
      Image(systemName: "xmark.circle.fill")
        .font(.title2)
        .opacity(0)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)

  }
}

private struct WorkLogDomainTopicView: View {
  let domainTitle: String
  let topicTitle: String
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("DOMAIN / TOPIC")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)

      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(.systemGray5))
          .frame(width: 44, height: 44)

        VStack(alignment: .leading, spacing: 4) {
          Text(domainTitle)
            .font(.caption)
            .foregroundColor(.secondary)
          Text(topicTitle)
            .font(.headline)
            .fontWeight(.semibold)
        }
        Spacer()
      }
      .padding(16)
      .background(Color(.systemBackground))
      .cornerRadius(12)
    }
  }
}

private struct WorkLogTimeSectionView: View {
  let workLogDraftStore: WorkLogDraftStore
  let onStartTimer: () -> Void
  let onStopTimer: () -> Void
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("TIME")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)

      VStack(spacing: 0) {
        // 開始
        HStack {
          Button(action: { onStartTimer() }) {
            HStack(spacing: 8) {
              Image(systemName: "play.circle.fill")
                .foregroundColor(workLogDraftStore.isRunning || workLogDraftStore.isReadyToPost ? .gray : .blue)
              Text("開始")
                .foregroundColor(workLogDraftStore.isRunning || workLogDraftStore.isReadyToPost ? .secondary : .blue)
            }
          }
          .disabled(workLogDraftStore.isRunning || workLogDraftStore.isReadyToPost)
          Spacer()
          DatePicker(
            "",
            selection: Binding(
              get: { workLogDraftStore.startDate ?? Date() },
              set: { newValue in
                let second = Calendar.current.component(.second, from: workLogDraftStore.startDate ?? Date())
                var components = Calendar.current.dateComponents(
                  [.year, .month, .day, .hour, .minute], from: newValue)
                components.second = second
                workLogDraftStore.startDate = Calendar.current.date(from: components)
              }
            ),
            in: ...Date(),
            displayedComponents: [.date, .hourAndMinute]
          )
          .labelsHidden()
          .fixedSize()
          .disabled(workLogDraftStore.isRunning)
          .environment(\.locale, Locale(identifier: "ja_JP"))
        }
        .padding(16)

        Divider().padding(.horizontal, 16)

        // 終了
        HStack {
          HStack(spacing: 8) {
            Image(systemName: "stop.circle.fill")
              .foregroundColor(.red)
            Text("終了")
              .foregroundColor(.primary)
          }
          Spacer()
          DatePicker(
            "",
            selection: Binding(
              get: { workLogDraftStore.endDate ?? Date() },
              set: { newValue in
                let second = Calendar.current.component(.second, from: workLogDraftStore.endDate ?? Date())
                var components = Calendar.current.dateComponents(
                  [.year, .month, .day, .hour, .minute], from: newValue)
                components.second = second
                workLogDraftStore.endDate = Calendar.current.date(from: components)
              }
            ),
            in: (workLogDraftStore.startDate ?? .distantPast)...Date(),
            displayedComponents: [.date, .hourAndMinute]
          )
          .labelsHidden()
          .fixedSize()
          .environment(\.locale, Locale(identifier: "ja_JP"))
        }
        .padding(16)
        .opacity(workLogDraftStore.isRunning ? 0 : 1)
        .frame(height: workLogDraftStore.isRunning ? 0 : nil)
        .clipped()

        Divider().padding(.horizontal, 16)
          .opacity(workLogDraftStore.isRunning ? 0 : 1)
          .frame(height: workLogDraftStore.isRunning ? 0 : nil)
          .clipped()

        // 経過時間
        HStack {
          HStack(spacing: 8) {
            Image(systemName: "clock")
              .foregroundColor(.secondary)
            Text("経過時間")
              .foregroundColor(.secondary)
          }
          Spacer()
          if workLogDraftStore.isRunning {
            Text(workLogDraftStore.displayTime)
              .font(.system(.body, design: .monospaced))
              .fontWeight(.bold)
              .foregroundColor(.blue)
          }
          else if let start = workLogDraftStore.startDate,
            let end = workLogDraftStore.endDate,
            start < end
          {
            Text(calculateDuration(from: start, to: end))
              .fontWeight(.bold)
              .foregroundColor(.blue)
          }
          else {
            Text("--:--:--")
              .foregroundColor(.secondary)
          }
        }
        .padding(16)
      }
      .background(Color(.systemBackground))
      .cornerRadius(12)

      // タイマー停止ボタン
      if workLogDraftStore.isRunning {
        Button(action: { onStopTimer() }) {
          HStack {
            Image(systemName: "stop.circle.fill")
            Text("タイマーを停止")
              .fontWeight(.semibold)
          }
          .frame(maxWidth: .infinity)
          .padding(14)
          .background(Color.red)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
      }
    }
  }
}

private struct WorkLogContentSectionView: View {
  @Binding var content: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("CONTENT")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)

      TextField("何をしましたか？", text: $content, axis: .vertical)
        .lineLimit(5...10)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
  }
}
