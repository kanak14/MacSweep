import SwiftUI

struct MacSweepOverviewView: View {
    @EnvironmentObject private var model: MacSweepAppModel
    let goToReview: (CleanupCategory?) -> Void

    private var groupedItems: [(CleanupCategory, [CleanupItem])] {
        Dictionary(grouping: model.items, by: \CleanupItem.category)
            .map { ($0.key, $0.value) }
            .sorted { $0.1.reduce(0) { $0 + $1.allocatedBytes } > $1.1.reduce(0) { $0 + $1.allocatedBytes } }
    }

    private var maxCategoryBytes: Int64 {
        groupedItems.map { $0.1.reduce(0) { $0 + $1.allocatedBytes } }.max() ?? 1
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: MacSweepTheme.spacing) {
                    header
                    storageHero
                    metricsRow
                    goalSection
                    categorySection
                    if let issues = model.snapshot?.issues, !issues.isEmpty {
                        issuesCard(issues)
                    }
                }
                .padding(MacSweepTheme.pagePadding)
                .padding(.bottom, 72)
            }

            bottomActionBar
        }
    }

    private var header: some View {
        SectionHeader(
            title: "Storage overview",
            subtitle: "Review each suggestion before removing anything."
        )
    }

    private var storageHero: some View {
        HStack(spacing: 32) {
            if let capacity = model.capacity {
                StorageRingView(
                    usedFraction: capacity.usedFraction,
                    centerTitle: MacSweepFormatting.bytes(capacity.available),
                    centerSubtitle: "available",
                    warning: capacity.usedFraction > 0.9
                )
                VStack(alignment: .leading, spacing: 12) {
                    Text("Storage health")
                        .font(.headline)
                    Text("\(MacSweepFormatting.bytes(capacity.used)) used of \(MacSweepFormatting.bytes(capacity.total))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        legendDot(color: MacSweepTheme.accent, label: "Used")
                        legendDot(color: Color(nsColor: .separatorColor).opacity(0.3), label: "Free")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else {
                Text("Capacity unavailable")
                    .foregroundStyle(.secondary)
                    .macSweepPanel()
            }
            Spacer()
        }
        .macSweepPanel()
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 14) {
            MetricTile(
                label: "Recoverable space",
                value: MacSweepFormatting.bytes(model.totalFoundBytes),
                detail: "Estimated from current scan",
                symbol: "arrow.down.circle"
            )
            MetricTile(
                label: "Suggested items",
                value: "\(model.items.count)",
                detail: "Ready for review",
                symbol: "list.bullet.rectangle"
            )
            MetricTile(
                label: "Last scan",
                value: lastScanLabel,
                detail: model.state == .scanning ? "In progress…" : "Local analysis only",
                symbol: "clock"
            )
        }
    }

    private var lastScanLabel: String {
        guard let date = model.snapshot?.date else { return "—" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(
                    title: "Safe cleanup goal",
                    subtitle: "Prefer regeneratable and re-downloadable items."
                )
                Spacer()
                Text("\(Int(model.reclaimTargetGB)) GB")
                    .font(MacSweepTheme.metricFont(size: 24))
                    .foregroundStyle(MacSweepTheme.accent)
            }
            Slider(value: $model.reclaimTargetGB, in: 1...100, step: 1)
                .tint(MacSweepTheme.accent)
            HStack {
                SafetyBadge(level: .regeneratable)
                SafetyBadge(level: .redownloadable)
                Spacer()
                Button("Pick safest matches") {
                    model.selectSafestForTarget()
                    goToReview(nil)
                }
                .buttonStyle(MacSweepSecondaryButtonStyle())
            }
        }
        .macSweepPanel()
    }

    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: "What we found",
                subtitle: "Grouped by category, sorted by size."
            )
            if groupedItems.isEmpty {
                Text("Run a scan to see suggested cleanup categories.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .macSweepPanel()
            } else {
                VStack(spacing: 12) {
                    ForEach(groupedItems, id: \.0) { category, items in
                        Button {
                            model.selectedReviewCategory = category
                            goToReview(category)
                        } label: {
                            CategoryBarRow(
                                category: category,
                                itemCount: items.count,
                                bytes: items.reduce(0) { $0 + $1.allocatedBytes },
                                maxBytes: maxCategoryBytes
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .macSweepPanel()
            }
        }
    }

    private func issuesCard(_ issues: [ScanIssue]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Some areas could not be scanned", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            ForEach(issues) { issue in
                Text("• \(issue.message)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .macSweepPanel()
    }

    private var bottomActionBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(model.items.count) items ready")
                    .font(.subheadline.weight(.semibold))
                Text("Review before removing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                goToReview(nil)
            } label: {
                Text("Review \(model.items.count) items")
            }
            .buttonStyle(MacSweepPrimaryButtonStyle())
            .disabled(model.items.isEmpty)
        }
        .padding(.horizontal, MacSweepTheme.pagePadding)
        .padding(.vertical, 14)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
