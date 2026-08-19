import SwiftUI

struct MacSweepHistoryView: View {
    @EnvironmentObject private var model: MacSweepAppModel

    var body: some View {
        Group {
            if model.receipts.isEmpty {
                ContentUnavailableView(
                    "No activity yet",
                    systemImage: "clock.badge.checkmark",
                    description: Text("Completed cleanups appear here as a local timeline.")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(model.receipts.enumerated()), id: \.element.id) { index, receipt in
                            ActivityTimelineRow(receipt: receipt, isLast: index == model.receipts.count - 1)
                        }
                    }
                    .padding(MacSweepTheme.pagePadding)
                }
            }
        }
    }
}

private struct ActivityTimelineRow: View {
    let receipt: CleanupReceipt
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(receipt.failureCount == 0 ? MacSweepTheme.accent : Color.orange)
                    .frame(width: 12, height: 12)
                if !isLast {
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor).opacity(0.4))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(receipt.finishedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                        outcomeBadge
                    }
                    Spacer()
                    Text(MacSweepFormatting.bytes(receipt.processedBytes))
                        .font(MacSweepTheme.metricFont(size: 20))
                }

                HStack(spacing: 16) {
                    summaryPill("\(receipt.successCount) succeeded", color: MacSweepTheme.accent)
                    if receipt.failureCount > 0 {
                        summaryPill("\(receipt.failureCount) failed", color: .red)
                    }
                    if receipt.binCount > 0 {
                        summaryPill("\(receipt.binCount) in Bin", color: .secondary)
                    }
                }

                DisclosureGroup("View details") {
                    VStack(spacing: 8) {
                        ForEach(receipt.entries) { entry in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: entry.succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(entry.succeeded ? MacSweepTheme.accent : .red)
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.itemName)
                                        .font(.subheadline.weight(.medium))
                                    Text(entry.message)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(MacSweepFormatting.bytes(entry.bytes))
                                    .font(.caption.monospacedDigit())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.top, 8)
                }
                .font(.caption.weight(.medium))
            }
            .macSweepPanel()
            .padding(.bottom, isLast ? 0 : 20)
        }
    }

    private var outcomeBadge: some View {
        Text(receipt.failureCount == 0 ? "Completed" : "Completed with issues")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(receipt.failureCount == 0 ? MacSweepTheme.accent : .orange)
            .background(
                (receipt.failureCount == 0 ? MacSweepTheme.accent : Color.orange).opacity(0.12),
                in: Capsule()
            )
    }

    private func summaryPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.1), in: Capsule())
    }
}
