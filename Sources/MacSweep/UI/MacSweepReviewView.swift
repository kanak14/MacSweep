import SwiftUI

struct MacSweepReviewView: View {
    @EnvironmentObject private var model: MacSweepAppModel

    @State private var query = ""
    @State private var safetyFilter: SafetyLevel?
    @State private var showConfirmation = false

    private var displayedItems: [CleanupItem] {
        model.items.filter { item in
            let categoryMatches = model.selectedReviewCategory.map { $0 == item.category } ?? true
            let safetyMatches = safetyFilter.map { $0 == item.safety } ?? true
            let queryMatches = query.isEmpty
                || item.name.localizedCaseInsensitiveContains(query)
                || item.reason.localizedCaseInsensitiveContains(query)
                || item.url?.path.localizedCaseInsensitiveContains(query) == true
            return categoryMatches && safetyMatches && queryMatches
        }
    }

    private var groupedByCategory: [(CleanupCategory, [CleanupItem])] {
        Dictionary(grouping: displayedItems, by: \.category)
            .map { ($0.key, $0.value) }
            .sorted { $0.0.title < $1.0.title }
    }

    private var availableCategories: [CleanupCategory] {
        Array(Set(model.items.map(\.category))).sorted { $0.title < $1.title }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detailPane
        }
        .alert("Remove selected items?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove \(model.selectedItems.count) items", role: .destructive) {
                Task { await model.cleanSelected() }
            }
        } message: {
            Text(confirmationMessage)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Suggested items",
                subtitle: "Filter by category or safety level."
            )

            TextField("Search", text: $query)
                .textFieldStyle(.roundedBorder)

            Picker("Safety", selection: $safetyFilter) {
                Text("All levels").tag(SafetyLevel?.none)
                ForEach(SafetyLevel.allCases, id: \.self) { level in
                    Text(level.title).tag(Optional(level))
                }
            }
            .labelsHidden()

            Text("Categories")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(spacing: 4) {
                    categorySidebarRow(nil, label: "All categories", count: model.items.count)
                    ForEach(availableCategories) { category in
                        let count = model.items.filter { $0.category == category }.count
                        categorySidebarRow(category, label: category.title, count: count)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button("Select visible") {
                    let allowed = displayedItems.filter { $0.safety != .irreplaceable }.map(\.id)
                    model.selectedIDs.formUnion(allowed)
                }
                .buttonStyle(MacSweepSecondaryButtonStyle())
                Button("Clear") { model.clearSelection() }
                    .buttonStyle(.plain)
                    .font(.caption)
            }
        }
        .padding(20)
        .frame(width: 240)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    private func categorySidebarRow(_ category: CleanupCategory?, label: String, count: Int) -> some View {
        let isSelected = model.selectedReviewCategory == category
        return         Button {
            model.selectedReviewCategory = category
        } label: {
            HStack {
                if let category {
                    Image(systemName: category.symbolName)
                        .font(.caption)
                        .foregroundStyle(category.color)
                        .frame(width: 18)
                }
                Text(label)
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                Text("\(count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isSelected ? MacSweepTheme.accentMuted : Color.clear,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var detailPane: some View {
        VStack(spacing: 0) {
            if displayedItems.isEmpty {
                ContentUnavailableView(
                    model.state == .scanning ? "Scanning…" : "Nothing to review",
                    systemImage: model.state == .scanning ? "magnifyingglass" : "checkmark.circle",
                    description: Text(
                        model.state == .scanning
                            ? "MacSweep is analyzing known safe locations."
                            : "Adjust filters or add a scan folder in Settings."
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(groupedByCategory, id: \.0) { category, items in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: category.symbolName)
                                        .foregroundStyle(category.color)
                                    Text(category.title)
                                        .font(.headline)
                                    Spacer()
                                    Text(MacSweepFormatting.bytes(items.reduce(0) { $0 + $1.allocatedBytes }))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                ForEach(items) { item in
                                    CleanupItemRow(item: item)
                                }
                            }
                        }
                    }
                    .padding(MacSweepTheme.pagePadding)
                }
            }

            Divider()
            selectionBar
        }
    }

    private var selectionBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(model.selectedItems.count) selected")
                    .font(.headline)
                Text("Up to \(MacSweepFormatting.bytes(model.selectedBytes))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if model.selectedItems.contains(where: { $0.safety == .irreplaceable }) {
                Label("Includes irreplaceable data", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Button {
                showConfirmation = true
            } label: {
                Label("Remove selected", systemImage: "trash")
            }
            .buttonStyle(MacSweepPrimaryButtonStyle())
            .disabled(model.selectedItems.isEmpty || model.state == .cleaning)
        }
        .padding(.horizontal, MacSweepTheme.pagePadding)
        .padding(.vertical, 14)
        .background(.bar)
    }

    private var confirmationMessage: String {
        let permanent = model.selectedItems.filter { $0.action == .deletePermanently }.count
        let binItems = model.selectedItems.filter { $0.action.usesBin }.count
        let systemItems = model.selectedItems.count - permanent - binItems
        if permanent > 0 {
            return "\(binItems) item(s) will move to Bin, \(permanent) item(s) already in Bin will be permanently deleted, and \(systemItems) system action(s) will run. Estimated selection: \(MacSweepFormatting.bytes(model.selectedBytes))."
        }
        return "\(binItems) filesystem item(s) will move to Bin. \(systemItems) simulator, Docker, or cloud action(s) cannot use Bin. Estimated selection: \(MacSweepFormatting.bytes(model.selectedBytes))."
    }
}

private struct CleanupItemRow: View {
    @EnvironmentObject private var model: MacSweepAppModel
    let item: CleanupItem

    private var selected: Bool { model.selectedIDs.contains(item.id) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button { model.toggle(item) } label: {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? MacSweepTheme.accent : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(selected ? "Deselect \(item.name)" : "Select \(item.name)")

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    SafetyBadge(level: item.safety)
                    Spacer()
                    Text(MacSweepFormatting.bytes(item.allocatedBytes))
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                }
                Text(item.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.consequence)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                HStack(spacing: 12) {
                    Text(item.action.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let path = item.url?.path {
                        Text(path)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    if item.url != nil {
                        Button("Reveal") { model.reveal(item) }
                            .buttonStyle(.link)
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(14)
        .background(
            selected ? MacSweepTheme.accentMuted : Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(selected ? MacSweepTheme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onTapGesture {
            model.toggle(item)
        }
    }
}
