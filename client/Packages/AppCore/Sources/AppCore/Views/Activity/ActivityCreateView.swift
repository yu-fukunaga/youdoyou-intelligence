import SwiftUI
import YouDoYouFirestore

struct ActivityCreateView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var activityState: ActivityState
  @EnvironmentObject var appState: AppState
  @StateObject var viewModel: ActivityCreateViewModel
  @State private var showDeleteConfirmation = false

  var body: some View {
    VStack(spacing: 0) {
      // ヘッダー
      HStack {
        Button {
          if activityState.isReadyToPost {
            showDeleteConfirmation = true
          }
          else {
            dismiss()
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
        // 右側のバランスを取るためダミーのスペース
        Image(systemName: "xmark.circle.fill")
          .font(.title2)
          .opacity(0)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)

      ScrollView {
        VStack(alignment: .leading, spacing: 24) {

          // Domain / Topic
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
                Text(viewModel.domain?.title ?? "")
                  .font(.caption)
                  .foregroundColor(.secondary)
                Text(viewModel.topic?.title ?? "")
                  .font(.headline)
                  .fontWeight(.semibold)
              }
              Spacer()
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
          }

          // 時間設定
          VStack(alignment: .leading, spacing: 12) {
            Text("TIME")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.secondary)

            VStack(spacing: 0) {
              // 開始
              HStack {
                Button(action: { viewModel.startTimer() }) {
                  HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                      .foregroundColor(activityState.isRunning || activityState.isReadyToPost ? .gray : .blue)
                    Text("開始")
                      .foregroundColor(activityState.isRunning || activityState.isReadyToPost ? .secondary : .blue)
                  }
                }
                .disabled(activityState.isRunning || activityState.isReadyToPost)
                Spacer()
                DatePicker(
                  "",
                  selection: Binding(
                    get: { activityState.startDate ?? Date() },
                    set: { newValue in
                      let second = Calendar.current.component(.second, from: activityState.startDate ?? Date())
                      var components = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute], from: newValue)
                      components.second = second
                      activityState.startDate = Calendar.current.date(from: components)
                    }
                  ),
                  in: ...Date(),
                  displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .fixedSize()
                .disabled(activityState.isRunning)
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
                    get: { activityState.endDate ?? Date() },
                    set: { newValue in
                      let second = Calendar.current.component(.second, from: activityState.endDate ?? Date())
                      var components = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute], from: newValue)
                      components.second = second
                      activityState.endDate = Calendar.current.date(from: components)
                    }
                  ),
                  in: (activityState.startDate ?? .distantPast)...Date(),
                  displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .fixedSize()
                .environment(\.locale, Locale(identifier: "ja_JP"))
              }
              .padding(16)
              .opacity(activityState.isRunning ? 0 : 1)
              .frame(height: activityState.isRunning ? 0 : nil)
              .clipped()

              Divider().padding(.horizontal, 16)
                .opacity(activityState.isRunning ? 0 : 1)
                .frame(height: activityState.isRunning ? 0 : nil)
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
                if activityState.isRunning {
                  Text(activityState.displayTime)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                }
                else if let start = activityState.startDate,
                  let end = activityState.endDate,
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
            if activityState.isRunning {
              Button(action: { viewModel.stopTimer() }) {
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

          // 内容
          VStack(alignment: .leading, spacing: 12) {
            Text("CONTENT")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.secondary)

            TextField("何をしましたか？", text: $activityState.content, axis: .vertical)
              .lineLimit(5...10)
              .padding(16)
              .background(Color(.systemBackground))
              .cornerRadius(12)
          }

          // エラー
          if let error = viewModel.error {
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
              await viewModel.post()
              if viewModel.error == nil {
                dismiss()
                NotificationCenter.default.post(name: NSNotification.Name("navigateToActivities"), object: nil)
              }
            }
          } label: {
            Text("Post")
              .fontWeight(.semibold)
              .frame(maxWidth: .infinity)
              .padding(14)
              .background(activityState.isReadyToPost ? Color.blue : Color.gray)
              .foregroundColor(.white)
              .cornerRadius(12)
          }
          .disabled(!activityState.isReadyToPost || viewModel.isLoading)

          Button {
            if activityState.isReadyToPost || activityState.isRunning {
              showDeleteConfirmation = true
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
    .interactiveDismissDisabled(activityState.isReadyToPost)
    .onAppear {
      if !activityState.isRunning && !activityState.isReadyToPost {
        let now = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970))
        activityState.startDate = now
        activityState.endDate = now
      }
    }
    .onDisappear {
      if !activityState.isReadyToPost && !activityState.isRunning {
        activityState.reset()
      }
    }
    .alert("入力を破棄しますか？", isPresented: $showDeleteConfirmation) {
      Button("キャンセル", role: .cancel) {}
      Button("破棄して閉じる", role: .destructive) {
        activityState.reset()
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
