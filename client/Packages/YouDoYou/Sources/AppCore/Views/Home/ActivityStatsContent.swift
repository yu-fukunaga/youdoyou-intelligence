import Charts
import SwiftUI

struct ActivityStatsContent: View {
  @StateObject private var viewModel = ActivityStatsViewModel()

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Today(
        hourlyIntensity: viewModel.hourlyIntensity,
        currentHour: viewModel.currentHour,
        hours: viewModel.todayTotal.hours,
        minutes: viewModel.todayTotal.minutes
      )
    }
    .onAppear { viewModel.startObserving() }
    .onDisappear { viewModel.stopObserving() }
  }
}

struct Today: View {
  let hourlyIntensity: [Int: Double]
  let currentHour: Int
  let hours: Int
  let minutes: Int

  var body: some View {
    HStack(alignment: .center, spacing: 40) {
      VStack(alignment: .leading, spacing: 6) {
        Text("今日")
          .font(.footnote)
          .fontWeight(.semibold)
          .foregroundColor(Color(.black))

        hourMinuteText(hours: hours, minutes: minutes)
      }

      HourlyDotsRow(hourlyIntensity: hourlyIntensity, currentHour: currentHour)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct HourlyDotsRow: View {
  let hourlyIntensity: [Int: Double]
  let currentHour: Int

  var body: some View {
    Chart {
      ForEach(0..<24, id: \.self) { hour in
        if let intensity = hourlyIntensity[hour], intensity > 0 {
          PointMark(
            x: .value("Hour", Double(hour) + 0.5),
            y: .value("Active", 0)
          )
          .symbolSize(36)
          .foregroundStyle(Color(red: 0.1, green: 0.55, blue: 0.55).opacity(intensity))
        }
      }

      RuleMark(x: .value("Now", Double(currentHour)))
        .foregroundStyle(Color(red: 0.85, green: 0.25, blue: 0.05))
        .lineStyle(StrokeStyle(lineWidth: 1.5))
    }
    .chartXAxis {
      AxisMarks(values: minorGridValues) { _ in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
          .foregroundStyle(Color(uiColor: .systemGray4))
      }
      AxisMarks(values: majorGridValues) { _ in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
          .foregroundStyle(Color(uiColor: .systemGray))
      }
      AxisMarks(values: [0, 6, 12, 18]) { value in
        AxisValueLabel {
          if let hour = value.as(Int.self) {
            Text("\(hour)時")
              .font(.caption2)
              .foregroundColor(.secondary)
              .offset(x: -4)
          }
        }
      }
    }
    .chartYAxis(.hidden)
    .chartXScale(domain: 0...24)
    .frame(height: 28)
  }

  // Gridlines sit at the real hour marks 0...24; dots sit at the midpoint of each hour.
  private let majorGridValues: [Double] = [0, 6, 12, 18, 24]

  private var minorGridValues: [Double] {
    Array(stride(from: 0.0, through: 24.0, by: 1.0)).filter { !majorGridValues.contains($0) }
  }
}

private func hourMinuteText(hours: Int, minutes: Int, suffix: String = "") -> Text {
  let hoursText = Text("\(hours)")
    .font(.title3)
    .fontWeight(.bold)
    .foregroundColor(Color(.black))
  let hUnit = Text(" h ")
    .font(.caption2)
    .foregroundColor(.secondary)
  let minutesText = Text("\(minutes)")
    .font(.title3)
    .fontWeight(.bold)
    .foregroundColor(Color(.black))
  let mUnit = Text(" m ")
    .font(.caption2)
    .foregroundColor(.secondary)
  let suffixText = Text(suffix)
    .font(.caption2)
    .foregroundColor(.secondary)

  return Text("\(hoursText)\(hUnit)\(minutesText)\(mUnit)\(suffixText)")
}
