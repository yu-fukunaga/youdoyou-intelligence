import SwiftUI

struct HomeView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      HomeCard {
        SectionHeaderLink(
          title: "アクティビティ",
          systemImage: "flame.fill",
          titleColor: Color(red: 0.85, green: 0.25, blue: 0.05),
          linkTitle: "Activities",
          destination: ActivitiesView()
        )
      } content: {
        ActivityStatsContent()
      }

      HomeCard(verticalPadding: 12) {
        HStack(spacing: 6) {
          Image(systemName: "square.and.pencil")
          Text("記録する")
        }
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundColor(.indigo)
      } content: {
        ActivityQuickStartContent()
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .navigationTitle("Home")
    .navigationBarTitleDisplayMode(.large)
    .background(Color(.systemGroupedBackground))
  }
}

struct HomeCard<Header: View, Content: View>: View {
  var verticalPadding: CGFloat = 16
  @ViewBuilder var header: Header
  @ViewBuilder var content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      header
        .padding(.horizontal)

      content
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color(.white))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }
  }
}

struct SectionHeaderLink<Destination: View>: View {
  let title: String
  var systemImage: String? = nil
  var titleColor: Color = Color(.black)
  let linkTitle: String
  let destination: Destination

  var body: some View {
    HStack {
      HStack(spacing: 6) {
        if let systemImage {
          Image(systemName: systemImage)
        }
        Text(title)
      }
      .font(.title3)
      .fontWeight(.semibold)
      .foregroundColor(titleColor)

      Spacer()

      NavigationLink(destination: destination) {
        HStack(spacing: 2) {
          Text(linkTitle)
          Image(systemName: "chevron.right")
        }
        .foregroundColor(.secondary)
        .font(.body)
      }
    }
  }
}
