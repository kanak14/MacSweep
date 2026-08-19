import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case review
    case activity

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .review: "Review"
        case .activity: "Activity"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: "circle.hexagongrid.fill"
        case .review: "square.stack.3d.up"
        case .activity: "clock.badge.checkmark"
        }
    }
}

struct MacSweepContentView: View {
    @EnvironmentObject private var model: MacSweepAppModel
    @State private var section: AppSection = .dashboard

    var body: some View {
        HStack(spacing: 0) {
            leftRail
            VStack(spacing: 0) {
                topToolbar
                Divider()
                mainContent
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task { await model.loadOnce() }
        .sheet(item: $model.latestReceipt) { receipt in
            MacSweepCleanupResultView(receipt: receipt)
                .environmentObject(model)
        }
    }

    private var leftRail: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                Image(systemName: "wind")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(MacSweepTheme.accent)
                Text("MacSweep")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 12)

            ForEach(AppSection.allCases) { item in
                RailButton(item: item, isSelected: section == item) {
                    section = item
                }
            }

            Spacer()
        }
        .frame(width: MacSweepTheme.railWidth)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.65))
        .overlay(alignment: .trailing) {
            Divider()
        }
    }

    private var topToolbar: some View {
        HStack(spacing: 16) {
            Text(section.title)
                .font(.title2.weight(.semibold))

            Spacer()

            StatusChip(
                title: model.state.title,
                detail: statusDetail,
                isActive: model.state == .scanning || model.state == .cleaning
            )

            Button {
                Task { await model.scan() }
            } label: {
                Label("Rescan", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(MacSweepSecondaryButtonStyle())
            .disabled(model.state == .scanning || model.state == .cleaning)

            SettingsLink {
                Image(systemName: "slider.horizontal.3")
                    .font(.body.weight(.medium))
                    .frame(width: 36, height: 36)
                    .background(Color(nsColor: .controlBackgroundColor), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MacSweepTheme.pagePadding)
        .frame(height: MacSweepTheme.toolbarHeight)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var mainContent: some View {
        switch section {
        case .dashboard:
            MacSweepOverviewView(goToReview: { category in
                model.selectedReviewCategory = category
                section = .review
            })
        case .review:
            MacSweepReviewView()
        case .activity:
            MacSweepHistoryView()
        }
    }

    private var statusDetail: String {
        if model.state == .scanning, model.totalScanners > 0 {
            return "\(model.completedScanners)/\(model.totalScanners) checks"
        }
        return "\(model.items.count) suggestions"
    }
}

private struct RailButton: View {
    let item: AppSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: item.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .foregroundStyle(isSelected ? MacSweepTheme.accent : .secondary)
                Text(item.title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(width: MacSweepTheme.railWidth - 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? MacSweepTheme.accentMuted : Color.clear,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
