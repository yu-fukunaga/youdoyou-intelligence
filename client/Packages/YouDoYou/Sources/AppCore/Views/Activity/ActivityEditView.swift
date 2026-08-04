// ActivityEditView.swift
import SwiftUI

struct ActivityEditView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var appState: AppState
  @ObservedObject var viewModel: ActivityDetailViewModel
  @State private var showDiscardConfirmation = false

  var body: some View {
    VStack(spacing: 0) {
      // ヘッダー
      HStack {
        Button {
          if viewModel.isEdited {
            showDiscardConfirmation = true
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
        Text("作業を編集")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
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
                HStack(spacing: 8) {
                  Image(systemName: "play.circle.fill")
                    .foregroundColor(.blue)
                  Text("開始")
                    .foregroundColor(.primary)
                }
                Spacer()
                DatePicker(
                  "",
                  selection: Binding(
                    get: { viewModel.startDate },
                    set: { newValue in
                      let second = Calendar.current.component(.second, from: viewModel.startDate)
                      var components = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute], from: newValue)
                      components.second = second
                      viewModel.startDate = Calendar.current.date(from: components) ?? newValue
                    }
                  ),
                  in: ...Date(),
                  displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .fixedSize()
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
                    get: { viewModel.endDate },
                    set: { newValue in
                      let second = Calendar.current.component(.second, from: viewModel.endDate)
                      var components = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute], from: newValue)
                      components.second = second
                      viewModel.endDate = Calendar.current.date(from: components) ?? newValue
                    }
                  ),
                  in: (viewModel.startDate)...Date(),
                  displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .fixedSize()
                .environment(\.locale, Locale(identifier: "ja_JP"))
              }
              .padding(16)

              Divider().padding(.horizontal, 16)

              // 経過時間
              HStack {
                HStack(spacing: 8) {
                  Image(systemName: "clock")
                    .foregroundColor(.secondary)
                  Text("経過時間")
                    .foregroundColor(.secondary)
                }
                Spacer()
                if viewModel.startDate < viewModel.endDate {
                  Text(calculateDuration(from: viewModel.startDate, to: viewModel.endDate))
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
          }

          // 内容
          VStack(alignment: .leading, spacing: 12) {
            Text("CONTENT")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundColor(.secondary)

            TextField("何をしましたか？", text: $viewModel.content, axis: .vertical)
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

          // 保存ボタン
          Button {
            Task {
              await viewModel.update()
              if viewModel.error == nil {
                dismiss()
              }
            }
          } label: {
            Text("保存")
              .fontWeight(.semibold)
              .frame(maxWidth: .infinity)
              .padding(14)
              .background(viewModel.isValid ? Color.blue : Color.gray)
              .foregroundColor(.white)
              .cornerRadius(12)
          }
          .disabled(!viewModel.isValid)

          Button {
            if viewModel.isEdited {
              showDiscardConfirmation = true
            }
            else {
              dismiss()
            }
          } label: {
            Text("キャンセル")
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
    .interactiveDismissDisabled(viewModel.isEdited)
    .alert("編集を破棄しますか？", isPresented: $showDiscardConfirmation) {
      Button("キャンセル", role: .cancel) {}
      Button("破棄して閉じる", role: .destructive) {
        dismiss()
      }
    } message: {
      Text("編集中のデータが失われます")
    }
    .onChange(of: viewModel.isUpdated) {
      if viewModel.isUpdated {
        dismiss()
      }
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
