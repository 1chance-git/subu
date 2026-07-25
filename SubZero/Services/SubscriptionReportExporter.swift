//
//  SubscriptionReportExporter.swift
//  Subu
//
//  Builds the two exportable report formats for a subscription list: a CSV
//  file (opens directly in Numbers, Excel, Sheets) and a formatted,
//  paginated PDF report grouped by Keep/Review/Cancel with a bar chart
//  (opens in Pages, Preview, Files). Both are written to a temp file so
//  they can be handed straight to a ShareLink.
//
//  The PDF is rendered from real SwiftUI views via `ImageRenderer` straight
//  into a Core Graphics PDF context (Apple's documented pattern for
//  SwiftUI → PDF). Earlier this used hand-drawn `NSAttributedString`/AppKit
//  text draws mixed with raw `CGContext` fills for the bar chart — the
//  text went through a "flipped" NSGraphicsContext while the bars were
//  filled directly against the context's native bottom-left-origin space,
//  so the two disagreed about which way was up and the chart came out
//  upside-down and misaligned relative to the text. Routing everything
//  through one SwiftUI view removes the split coordinate systems and also
//  drops the AppKit dependency, which never compiled for iOS anyway.
//

import Foundation
import SwiftUI
import Charts

enum SubscriptionReportExporter {
    // MARK: CSV

    /// Rows are grouped Keep → Review → Cancel (then alphabetically within
    /// each group) so the spreadsheet reads as an organized report rather
    /// than whatever order SwiftData happened to return, and a UTF-8 BOM is
    /// included so Numbers/Excel reliably detect the encoding instead of
    /// guessing and mangling any accented characters.
    static func csvData(for subscriptions: [Subscription]) -> Data {
        let header = ["Status", "Name", "Provider", "Category", "Cancellation Difficulty", "Notes"]
        let rows = groupedByStatus(subscriptions).map { subscription in
            [
                subscription.status.rawValue,
                subscription.name,
                subscription.provider,
                subscription.category.rawValue,
                subscription.cancellationDifficulty.rawValue,
                subscription.notes,
            ]
        }

        let csvString = ([header] + rows)
            .map { $0.map(csvEscape).joined(separator: ",") }
            .joined(separator: "\r\n") + "\r\n"

        var data = Data([0xEF, 0xBB, 0xBF]) // UTF-8 BOM
        data.append(Data(csvString.utf8))
        return data
    }

    private static func csvEscape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else { return field }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    static func writeCSVToTempFile(for subscriptions: [Subscription]) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Subu-Subscriptions.csv")
        try csvData(for: subscriptions).write(to: url, options: .atomic)
        return url
    }

    // MARK: Shared ordering

    private static let statusOrder: [SubscriptionStatus] = [.keep, .review, .cancel]

    private static func groupedByStatus(_ subscriptions: [Subscription]) -> [Subscription] {
        statusOrder.flatMap { status in
            subscriptions
                .filter { $0.status == status }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    // MARK: PDF

    @MainActor
    static func pdfData(for subscriptions: [Subscription]) -> Data {
        let pageSize = CGSize(width: 612, height: 792) // US Letter
        let margin: CGFloat = 36
        let contentSize = CGSize(width: pageSize.width - margin * 2, height: pageSize.height - margin * 2)

        let items = lineItems(for: subscriptions)
        let pages = paginate(items, contentHeight: contentSize.height)

        let data = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard
            let consumer = CGDataConsumer(data: data as CFMutableData),
            let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else {
            return Data()
        }

        for (index, pageItems) in pages.enumerated() {
            let pageView = ReportPageView(
                isFirstPage: index == 0,
                subscriptions: subscriptions,
                items: pageItems,
                size: contentSize
            )
            .environment(\.colorScheme, .light)

            let renderer = ImageRenderer(content: pageView)
            renderer.proposedSize = ProposedViewSize(contentSize)

            pdfContext.beginPDFPage(nil)
            pdfContext.saveGState()
            pdfContext.translateBy(x: margin, y: margin)
            renderer.render { _, renderInContext in
                renderInContext(pdfContext)
            }
            pdfContext.restoreGState()
            pdfContext.endPDFPage()
        }
        pdfContext.closePDF()

        return data as Data
    }

    @MainActor
    static func writePDFToTempFile(for subscriptions: [Subscription]) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Subu-Subscriptions.pdf")
        try pdfData(for: subscriptions).write(to: url, options: .atomic)
        return url
    }

    // MARK: Pagination

    private static func lineItems(for subscriptions: [Subscription]) -> [ReportLineItem] {
        statusOrder.flatMap { status -> [ReportLineItem] in
            let group = subscriptions
                .filter { $0.status == status }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            guard !group.isEmpty else { return [] }
            return [.sectionHeader(status, group.count)] + group.map(ReportLineItem.row)
        }
    }

    /// Greedily packs line items into pages using estimated row heights that
    /// match `ReportPageView`'s fonts/padding, keeping the header+chart
    /// block only on page one and avoiding a section header stranded alone
    /// at the bottom of a page.
    private static func paginate(_ items: [ReportLineItem], contentHeight: CGFloat) -> [[ReportLineItem]] {
        let headerBlockHeight: CGFloat = 300
        let sectionHeaderHeight: CGFloat = 38
        let rowHeight: CGFloat = 44

        guard !items.isEmpty else { return [[]] }

        var pages: [[ReportLineItem]] = []
        var currentPage: [ReportLineItem] = []
        var remaining = contentHeight - headerBlockHeight

        for item in items {
            let height: CGFloat
            switch item {
            case .sectionHeader: height = sectionHeaderHeight
            case .row: height = rowHeight
            }

            let isOrphanHeader: Bool = {
                guard case .sectionHeader = item else { return false }
                return remaining - height < rowHeight
            }()

            if height > remaining || isOrphanHeader {
                pages.append(currentPage)
                currentPage = []
                remaining = contentHeight
            }

            currentPage.append(item)
            remaining -= height
        }

        if !currentPage.isEmpty {
            pages.append(currentPage)
        }
        return pages
    }
}

// MARK: - ReportLineItem

/// One row of PDF content: either a status section header or a single
/// subscription. File-scoped (not nested) so both `SubscriptionReportExporter`
/// and `ReportPageView` share the same type.
private enum ReportLineItem: Identifiable {
    case sectionHeader(SubscriptionStatus, Int)
    case row(Subscription)

    var id: String {
        switch self {
        case .sectionHeader(let status, _): return "header-\(status.rawValue)"
        case .row(let subscription): return "row-\(subscription.id)"
        }
    }
}

// MARK: - ReportPageView

private struct ReportPageView: View {
    let isFirstPage: Bool
    let subscriptions: [Subscription]
    let items: [ReportLineItem]
    let size: CGSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isFirstPage {
                headerBlock
            }

            ForEach(items) { item in
                switch item {
                case .sectionHeader(let status, let count):
                    Text("\(status.rawValue) (\(count))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                case .row(let subscription):
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subscription.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.black)
                        Text("\(subscription.provider) · \(subscription.category.rawValue) · \(subscription.cancellationDifficulty.rawValue) to cancel")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                    }
                    .padding(.bottom, 10)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background(Color.white)
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Subu Subscription Report")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)
            Text("Generated \(Date().formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: 12))
                .foregroundStyle(.gray)

            Chart(statusCounts, id: \.status) { entry in
                BarMark(
                    x: .value("Count", entry.count),
                    y: .value("Status", entry.status.rawValue)
                )
                .foregroundStyle(color(for: entry.status))
                .annotation(position: .trailing) {
                    Text("\(entry.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 100)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
    }

    private var statusCounts: [(status: SubscriptionStatus, count: Int)] {
        SubscriptionStatus.allCases.map { status in
            (status, subscriptions.filter { $0.status == status }.count)
        }
    }

    private func color(for status: SubscriptionStatus) -> Color {
        switch status {
        case .keep: return .green
        case .review: return .yellow
        case .cancel: return .red
        }
    }
}
