import Charts
import SwiftUI

struct ReportView: View {
  @StateObject private var viewModel = ReportViewModel()
  @EnvironmentObject private var appState: AppState

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        periodPicker
        dateRangeHeader
        chartSection
        summaryList
      }
    }
    .navigationTitle("Report")
    .navigationBarTitleDisplayMode(.large)
    .toolbarBackground(.hidden, for: .navigationBar)
    .background(Color(.systemGroupedBackground))
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        UserIconButton()
      }
    }
    .task {
      await viewModel.loadIfNeeded()
    }
    .onChange(of: viewModel.periodType) {
      Task { await viewModel.loadIfNeeded() }
    }
  }

  // MARK: - Period Picker

  private var periodPicker: some View {
    Picker("Period", selection: $viewModel.periodType) {
      ForEach(PeriodType.allCases, id: \.self) { type in
        Text(type.rawValue).tag(type)
      }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
    .padding(.top, 8)
  }

  // MARK: - Date Range Header

  private var dateRangeHeader: some View {
    HStack {
      VStack(alignment: .leading) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("合計時間")
              .font(.caption2)
              .foregroundStyle(.secondary)
            styledDuration(viewModel.headerTotalDuration)
          }
          Divider()
            .frame(height: 32)
          VStack(alignment: .leading, spacing: 4) {
            Text("平均時間")
              .font(.caption2)
              .foregroundStyle(.secondary)
            styledDuration(viewModel.headerAverageDuration)
          }
        }
        Text(viewModel.headerDateRangeText)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      groupingUnitButton
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
  }

  private func styledDuration(_ duration: TimeInterval) -> Text {
    let totalMinutes = Int(duration) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60

    func number(_ value: Int) -> Text {
      Text("\(value)").font(.headline).fontWeight(.bold)
    }
    func unit(_ label: String) -> Text {
      Text(label).font(.callout).foregroundStyle(.secondary)
    }

    if hours == 0 { return number(minutes) + unit("分") }
    if minutes == 0 { return number(hours) + unit("時間") }
    return number(hours) + unit("時間") + Text(" ") + number(minutes) + unit("分")
  }

  private var groupingUnitButton: some View {
    let isTopic = viewModel.groupingUnit == .topic

    return Button {
      viewModel.groupingUnit = isTopic ? .domain : .topic
    } label: {
      Image(systemName: "list.bullet.indent")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(isTopic ? Color(.systemBackground) : .secondary)
        .frame(width: 24, height: 24)
        .background(isTopic ? Color.primary : Color(.systemFill))
        .clipShape(Circle())
    }
  }

  // MARK: - Chart Section

  @ViewBuilder
  private var chartSection: some View {
    if viewModel.periodType == .day {
      dayTimeline
    }
    else {
      barChart
    }
  }

  // MARK: - Day Timeline

  private var dayTimeline: some View {
    let activities = viewModel.timelineActivities
    let cal = Calendar.current
    let dayStart = cal.startOfDay(for: viewModel.currentDate)
    let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!

    return Chart(activities) { activity in
      RectangleMark(
        x: .value("Activity", ""),
        yStart: .value("Start", activity.startedAt),
        yEnd: .value("End", activity.endedAt)
      )
      .foregroundStyle(viewModel.timelineColor(for: activity, domains: appState.domains))
      .cornerRadius(4)
      .annotation(position: .overlay, alignment: .topLeading) {
        VStack(alignment: .leading, spacing: 1) {
          Text(
            viewModel.timelineTitle(
              for: viewModel.groupId(for: activity),
              domains: appState.domains
            )
          )
          .font(.caption2)
          .fontWeight(.medium)
          Text(activity.endedAt.timeIntervalSince(activity.startedAt).reportText)
            .font(.caption2)
        }
        .foregroundStyle(.white)
        .padding(4)
      }
    }
    .chartYScale(domain: dayStart...dayEnd)
    .chartScrollableAxes(.vertical)
    .chartYVisibleDomain(length: 12 * 3600)
    .chartScrollPosition(initialY: viewModel.timelineScrollStart)
    .chartXAxis(.hidden)
    .chartYAxis {
      AxisMarks(values: .stride(by: .hour, count: 1)) { value in
        AxisValueLabel {
          if let date = value.as(Date.self) {
            Text("\(cal.component(.hour, from: date)):00")
              .font(.caption2)
          }
        }
        AxisGridLine()
      }
    }
    .frame(height: 400)
    .padding(.horizontal)
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 50, coordinateSpace: .local)
        .onEnded { value in
          if abs(value.translation.width) > abs(value.translation.height) {
            if value.translation.width < -50 {
              viewModel.movePeriod(by: 1)
            }
            else if value.translation.width > 50 {
              viewModel.movePeriod(by: -1)
            }
          }
        }
    )
  }

  // MARK: - Bar Chart

  private var barChart: some View {
    let bars = viewModel.barChartColumns(domains: appState.domains)

    return Chart {
      ForEach(bars) { bar in
        ForEach(Array(bar.segments.enumerated()), id: \.element.id) { index, segment in
          BarMark(
            x: .value("Period", bar.label),
            y: .value("Duration", segment.duration / 3600)
          )
          .foregroundStyle(segment.color)
          .annotation(position: .top) {
            if index == bar.segments.count - 1, bar.total > 0 {
              Text(bar.total.reportText)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            }
          }
        }
      }
    }
    .chartYAxis {
      AxisMarks(position: .trailing) { value in
        AxisValueLabel {
          if let hours = value.as(Double.self) {
            Text("\(Int(hours))h")
              .font(.caption2)
          }
        }
        AxisGridLine()
      }
    }
    .frame(height: 120)
    .padding(.horizontal)
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 30)
        .onEnded { value in
          if value.translation.width < -30 {
            viewModel.movePeriod(by: 1)
          }
          else if value.translation.width > 30 {
            viewModel.movePeriod(by: -1)
          }
        }
    )
  }

  // MARK: - Summary List

  private var summaryList: some View {
    let rows = viewModel.listRows(domains: appState.domains)

    return LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
      Section {
        ForEach(rows) { row in
          summaryRowView(row)
        }
      } header: {
        totalRowView
      }
    }
    .padding(.top, 16)
  }

  private var totalRowView: some View {
    let isSelected = viewModel.selectedItemId == nil

    return Button {
      viewModel.selectedItemId = nil
    } label: {
      HStack(spacing: 10) {
        Text("合計")
          .font(.subheadline)
          .fontWeight(.semibold)
        Spacer()
        Text(viewModel.listTotalDuration.reportText)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal)
      .padding(.vertical, 12)
      .background(isSelected ? Color(.systemFill) : Color(.systemGroupedBackground))
    }
    .buttonStyle(.plain)
  }

  private func summaryRowView(_ row: ListRow) -> some View {
    let isSelected = viewModel.selectedItemId == row.id

    return Button {
      viewModel.toggleItem(row.id)
    } label: {
      HStack(spacing: 10) {
        Circle()
          .fill(row.color)
          .frame(width: 10, height: 10)
        VStack(alignment: .leading, spacing: 1) {
          if let subtitle = row.subtitle {
            Text(subtitle)
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
          Text(row.title)
            .font(.subheadline)
            .lineLimit(1)
        }
        Spacer()
        Text(row.total.reportText)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal)
      .padding(.vertical, 12)
      .background(isSelected ? Color(.systemFill) : .clear)
    }
    .buttonStyle(.plain)
  }
}
