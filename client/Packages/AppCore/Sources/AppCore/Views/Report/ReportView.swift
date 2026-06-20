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
        domainChips
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
    VStack(spacing: 4) {
      Text(viewModel.totalDuration.reportText)
        .font(.title)
        .fontWeight(.bold)
      Text(viewModel.dateRangeText)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
  }

  // MARK: - Domain Chips

  private var domainChips: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        chipButton(title: "All", isSelected: viewModel.selectedDomainId == nil) {
          viewModel.selectDomain(nil)
        }
        ForEach(appState.domains) { domain in
          chipButton(
            title: domain.title,
            isSelected: viewModel.selectedDomainId == domain.id
          ) {
            viewModel.selectDomain(domain.id)
          }
        }
      }
      .padding(.horizontal)
    }
    .padding(.bottom, 12)
  }

  private func chipButton(
    title: String, isSelected: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline)
        .fontWeight(isSelected ? .semibold : .regular)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(isSelected ? Color.primary : Color(.systemBackground))
        .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
        .clipShape(Capsule())
        .overlay(
          Capsule()
            .stroke(Color(.separator), lineWidth: isSelected ? 0 : 0.5)
        )
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
    let activities = viewModel.dayActivities
    let cal = Calendar.current
    let dayStart = cal.startOfDay(for: viewModel.currentDate)
    let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!

    return Chart(activities) { activity in
      RectangleMark(
        x: .value("Activity", ""),
        yStart: .value("Start", activity.startedAt),
        yEnd: .value("End", activity.endedAt)
      )
      .foregroundStyle(viewModel.colorForActivity(activity, domains: appState.domains))
      .cornerRadius(4)
      .annotation(position: .overlay, alignment: .topLeading) {
        VStack(alignment: .leading, spacing: 1) {
          Text(
            viewModel.resolveTitle(
              id: activity[keyPath: viewModel.selectedDomainId != nil ? \Activity.topicId : \Activity.domainId],
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
    .chartScrollPosition(initialY: viewModel.dayScrollStart)
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
    let bars = viewModel.chartBars(domains: appState.domains)

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
    .frame(height: 240)
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
    let rows = viewModel.summaryRows(domains: appState.domains)

    return VStack(spacing: 0) {
      ForEach(rows) { row in
        summaryRowView(row)
      }
    }
    .padding(.top, 16)
  }

  private func summaryRowView(_ row: SummaryRow) -> some View {
    let isSelected = viewModel.selectedTopicId == row.id
    let isTopic = viewModel.selectedDomainId != nil

    return Button {
      if isTopic {
        viewModel.toggleTopic(row.id)
      }
    } label: {
      HStack(spacing: 10) {
        Circle()
          .fill(row.color)
          .frame(width: 10, height: 10)
        Text(row.title)
          .font(.subheadline)
          .lineLimit(1)
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
    .disabled(!isTopic)
  }
}
