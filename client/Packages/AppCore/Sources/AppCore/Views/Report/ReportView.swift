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
    ZStack {
      HStack(spacing: 4) {
        periodMoveButton(systemImage: "chevron.left", offset: -1)
        Text(viewModel.headerDateRangeText)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .contentTransition(.opacity)
          .animation(.easeInOut, value: viewModel.headerDateRangeText)
        periodMoveButton(systemImage: "chevron.right", offset: 1)
      }
      HStack {
        if !viewModel.isViewingToday {
          todayButton
        }
        Spacer()
      }
      HStack {
        Spacer()
        groupingUnitButton
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
  }

  private var todayButton: some View {
    Button {
      viewModel.jumpToToday()
    } label: {
      Text("今日")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
    }
  }

  private func periodMoveButton(systemImage: String, offset: Int) -> some View {
    Button {
      viewModel.movePeriod(by: offset)
    } label: {
      Image(systemName: systemImage)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: 20, height: 20)
    }
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

  // Custom-drawn (not Swift Charts): gridlines/labels are always computed fresh from
  // live data with no animation, while each bar column animates its own height
  // independently via `.animation(value:)`, so the background never gets swept into
  // a bar's animation transaction.
  private static let barChartPlotHeight: CGFloat = 90
  private static let barSpacing: CGFloat = 10
  private static let axisGutterWidth: CGFloat = 28
  private static let labelAnimationDelay: TimeInterval = 0.1
  private static let dataAnimationDelay: TimeInterval = 0.3
  private static let dataAnimationDuration: TimeInterval = 0.5

  // Compact "3h35m" form for the per-bar annotation, kept separate from the
  // Japanese "3時間35分" used elsewhere (header, list, day chart).
  private func compactDuration(_ duration: TimeInterval) -> String {
    let totalMinutes = Int(duration) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours == 0 { return "\(minutes)m" }
    if minutes == 0 { return "\(hours)h" }
    return "\(hours)h\(minutes)m"
  }

  private var barChart: some View {
    let bars = viewModel.barChartColumns(domains: appState.domains)
    let maxHours = max((bars.map { $0.total / 3600 }.max() ?? 0) * 1.15, 1)
    // Placeholder columns (beyond the current PeriodType's real bucket count) are
    // squeezed to width 0 so only real columns share the available width - see
    // ReportViewModel.maxBarSlots for why the column count itself never changes.
    let realCount = max(bars.filter { !$0.isPlaceholder }.count, 1)

    return GeometryReader { geometry in
      let plotWidth = geometry.size.width - Self.axisGutterWidth
      let totalSpacing = Self.barSpacing * CGFloat(bars.count - 1)
      let columnWidth = max((plotWidth - totalSpacing) / CGFloat(realCount), 0)

      VStack(alignment: .leading, spacing: 4) {
        ZStack(alignment: .topLeading) {
          barChartGridlines(maxHours: maxHours, columnWidth: columnWidth, realCount: realCount)
          HStack(alignment: .bottom, spacing: Self.barSpacing) {
            ForEach(bars) { bar in
              barColumn(bar, maxHours: maxHours, width: bar.isPlaceholder ? 0 : columnWidth)
            }
          }
        }
        .frame(height: Self.barChartPlotHeight)

        HStack(spacing: Self.barSpacing) {
          ForEach(bars) { bar in
            Text(bar.label)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .frame(width: bar.isPlaceholder ? 0 : columnWidth)
              .clipped()
              .contentTransition(.opacity)
              .animation(.easeInOut.delay(Self.labelAnimationDelay), value: bar.label)
              .animation(.easeInOut.delay(Self.labelAnimationDelay), value: columnWidth)
          }
        }
      }
    }
    .frame(height: 120)
    .padding(.horizontal)
  }

  // Gridline positions are fixed fractions of the plot height (never move, no
  // dependency on data at all). Only the value label at each fixed position
  // changes/animates as `maxHours` changes.
  private static let gridlineFractions: [Double] = [0, 0.5, 1]

  private func barChartGridlines(maxHours: Double, columnWidth: CGFloat, realCount: Int) -> some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        ForEach(Array(Self.gridlineFractions.enumerated()), id: \.offset) { _, fraction in
          let y = geometry.size.height * (1 - CGFloat(fraction))
          let tickValue = fraction * maxHours

          Path { path in
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: geometry.size.width - Self.axisGutterWidth, y: y))
          }
          .stroke(Color(.separator), lineWidth: 0.5)

          Text("\(Int(tickValue))h")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(width: 26, alignment: .leading)
            .position(x: geometry.size.width - 12, y: y)
            .contentTransition(.numericText())
            .animation(.easeInOut.delay(Self.labelAnimationDelay), value: tickValue)
        }

        // Dashed separator centered in the gap between each pair of real bars.
        ForEach(1..<realCount, id: \.self) { index in
          let x = CGFloat(index) * (columnWidth + Self.barSpacing) - Self.barSpacing / 2

          Path { path in
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
          }
          .stroke(Color(.separator), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
          .animation(
            .easeInOut(duration: Self.dataAnimationDuration).delay(Self.dataAnimationDelay), value: columnWidth)
        }
      }
    }
  }

  private func barColumn(_ bar: BarChartColumn, maxHours: Double, width: CGFloat) -> some View {
    VStack(spacing: 0) {
      Spacer(minLength: 0)

      VStack(spacing: 2) {
        Text(bar.total > 0 ? compactDuration(bar.total) : "")
          .font(.system(size: 9))
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .fixedSize(horizontal: true, vertical: false)
          .contentTransition(.opacity)
          .animation(.easeInOut(duration: Self.dataAnimationDuration).delay(Self.dataAnimationDelay), value: bar.total)

        VStack(spacing: 0) {
          ForEach(bar.segments) { segment in
            Rectangle()
              .fill(segment.color)
              .frame(height: CGFloat(segment.duration / 3600 / maxHours) * Self.barChartPlotHeight)
          }
        }
        .padding(.horizontal, 4)
      }
    }
    .frame(width: width, height: Self.barChartPlotHeight)
    .clipped()
    .animation(.easeInOut(duration: Self.dataAnimationDuration).delay(Self.dataAnimationDelay), value: bar.total)
    .animation(.easeInOut(duration: Self.dataAnimationDuration).delay(Self.dataAnimationDelay), value: width)
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
