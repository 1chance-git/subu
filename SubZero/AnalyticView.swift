//
///
//  AnalyticsView.swift
//  SubZero
//
//  Spending analytics powered entirely by Swift Charts, updating
//  automatically as the underlying SwiftData store changes.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query private var subscriptions: [Subscription]

    private struct CategorySpending: Identifiable {
        let id = UUID()
        let category: SubscriptionCategory
        let total: Double
    }

    private struct MonthlyProjection: Identifiable {
        let id = UUID()
        let label: String
        let amount: Double
    }

    private var categorySpending: [CategorySpending] {
        let grouped = Dictionary(grouping: subscriptions, by: { $0.category })
        return SubscriptionCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            let total = items.reduce(0) { $0 + $1.normalizedMonthlyCost }
            return CategorySpending(category: category, total: total)
        }
        .sorted { $0.total > $1.total }
    }

    private var totalMonthly: Double {
        subscriptions.reduce(0) { $0 + $1.normalizedMonthlyCost }
    }

    private var upcomingMonths: [MonthlyProjection] {
        let calendar = Calendar.current
        let today = Date()
        var results: [MonthlyProjection] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        for offset in 0..<6 {
            guard let monthDate = calendar.date(byAdding: .month, value: offset, to: today) else { continue }
            results.append(MonthlyProjection(label: formatter.string(from: monthDate), amount: totalMonthly))
        }
        return results
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if subscriptions.isEmpty {
                        emptyState
                    } else {
                        categoryChartSection
                        projectionChartSection
                        categoryBreakdownList
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
        }
    }

    // MARK: Category Bar Chart

    private var categoryChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)

            Chart(categorySpending) { entry in
                BarMark(
                    x: .value("Category", entry.category.rawValue),
                    y: .value("Monthly Cost", entry.total)
                )
                .foregroundStyle(entry.category.tintColor.gradient)
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text(formattedAmount(entry.total))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 240)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .accessibilityLabel("Bar chart of monthly spending by category")
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Projection Line Chart

    private var projectionChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("6-Month Projection")
                .font(.headline)
            Text("Assumes your current subscriptions remain active")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(upcomingMonths) { projection in
                LineMark(
                    x: .value("Month", projection.label),
                    y: .value("Projected Spend", projection.amount)
                )
                .interpolationMethod(.catmullRom)
                .symbol(Circle())
                .foregroundStyle(Color.accentColor)

                AreaMark(
                    x: .value("Month", projection.label),
                    y: .value("Projected Spend", projection.amount)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .accessibilityLabel("Line chart projecting spending over the next six months")
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Breakdown List

    private var categoryBreakdownList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(categorySpending) { entry in
                    HStack {
                        Image(systemName: entry.category.symbolName)
                            .foregroundStyle(entry.category.tintColor)
                            .frame(width: 24)
                        Text(entry.category.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Text(formattedAmount(entry.total))
                            .font(.subheadline.weight(.semibold))
                        Text(percentageLabel(for: entry.total))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 46, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func percentageLabel(for amount: Double) -> String {
        guard totalMonthly > 0 else { return "0%" }
        let percentage = (amount / totalMonthly) * 100
        return String(format: "%.0f%%", percentage)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No data yet")
                .font(.headline)
            Text("Add a subscription to see your spending analytics.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func formattedAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(PreviewSampleData.container)
}
