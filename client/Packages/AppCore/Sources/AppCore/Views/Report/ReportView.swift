import Charts
import Foundation
import SwiftUI

struct ReportView: View {
  @StateObject private var viewModel = ReportViewModel()
  @EnvironmentObject private var appState: AppState

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        periodPicker
        if viewModel.periodType == .day {
          dayHeader
          dayClockChart
        }
        else {
          dateRangeHeader
          barChart
        }
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

  // MARK: - Day Header

  private static let clockChartSize: CGFloat = 200

  private var dayHeader: some View {
    HStack {
      Text(viewModel.headerDateRangeText)
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
      groupingUnitButton
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
  }

  // MARK: - Day Clock Chart

  private var dayClockChart: some View {
    let segments = viewModel.clockSegments(domains: appState.domains)

    return ZStack {
      clockHourLabels
        .frame(width: Self.clockChartSize + 40, height: Self.clockChartSize + 40)

      Chart(segments) { segment in
        SectorMark(
          angle: .value("Duration", segment.duration),
          innerRadius: .ratio(0.72),
          angularInset: 0
        )
        .foregroundStyle(segment.color)
      }
      .frame(width: Self.clockChartSize, height: Self.clockChartSize)

      VStack(spacing: 2) {
        Text("合計")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Text(viewModel.headerTotalDuration.reportText)
          .font(.title2)
          .fontWeight(.bold)
      }
    }
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity)
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

  // Hour numbers (0-23) around the chart's outer edge, like a clock face.
  private var clockHourLabels: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let radius = Self.clockChartSize / 2 + 12

      for hour in 0..<24 {
        let angle = Angle(degrees: Double(hour) / 24 * 360 - 90).radians
        let point = CGPoint(
          x: center.x + CGFloat(cos(angle)) * radius,
          y: center.y + CGFloat(sin(angle)) * radius
        )
        let text = Text("\(hour)")
          .font(.system(size: 9))
          .foregroundStyle(.secondary)
        context.draw(text, at: point)
      }
    }
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
