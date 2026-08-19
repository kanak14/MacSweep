import SwiftUI

enum MacSweepTheme {
    static let accent = Color(red: 0.11, green: 0.69, blue: 0.56)
    static let accentMuted = Color(red: 0.11, green: 0.69, blue: 0.56).opacity(0.14)
    static let railWidth: CGFloat = 76
    static let pagePadding: CGFloat = 32
    static let cornerRadius: CGFloat = 14
    static let spacing: CGFloat = 20
    static let toolbarHeight: CGFloat = 52

    static func metricFont(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

extension SafetyLevel {
    var color: Color {
        switch self {
        case .regeneratable: Color(red: 0.18, green: 0.72, blue: 0.45)
        case .redownloadable: Color(red: 0.22, green: 0.55, blue: 0.92)
        case .reviewRequired: Color(red: 0.95, green: 0.58, blue: 0.18)
        case .irreplaceable: Color(red: 0.92, green: 0.32, blue: 0.32)
        }
    }
}

extension CleanupCategory {
    var color: Color {
        switch self {
        case .xcode, .developerCaches: .indigo
        case .simulators: .cyan
        case .appCaches: .purple
        case .logs: .gray
        case .downloads, .archives: .blue
        case .oldFiles: .orange
        case .duplicates: .mint
        case .backups: .brown
        case .cloudCopies: .teal
        case .trash, .appLeftovers: .red
        }
    }
}

struct MacSweepPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                Color(nsColor: .controlBackgroundColor),
                in: RoundedRectangle(cornerRadius: MacSweepTheme.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: MacSweepTheme.cornerRadius, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 0.5)
            }
    }
}

extension View {
    func macSweepPanel() -> some View { modifier(MacSweepPanelModifier()) }
    func card() -> some View { macSweepPanel() }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MetricTile: View {
    let label: String
    let value: String
    var detail: String?
    var symbol: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MacSweepTheme.accent)
                }
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(MacSweepTheme.metricFont(size: 22))
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .macSweepPanel()
    }
}

struct SafetyBadge: View {
    let level: SafetyLevel

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(level.color)
                .frame(width: 6, height: 6)
            Text(level.title)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(level.color)
        .background(level.color.opacity(0.12), in: Capsule())
    }
}

struct StatusChip: View {
    let title: String
    let detail: String
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if isActive {
                ProgressView().controlSize(.small)
            } else {
                Circle()
                    .fill(MacSweepTheme.accent)
                    .frame(width: 7, height: 7)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.semibold))
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(MacSweepTheme.accentMuted, in: Capsule())
    }
}

struct StorageRingView: View {
    let usedFraction: Double
    let centerTitle: String
    let centerSubtitle: String
    var ringColor: Color = MacSweepTheme.accent
    var warning: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(nsColor: .separatorColor).opacity(0.25), lineWidth: 14)
            Circle()
                .trim(from: 0, to: min(max(usedFraction, 0), 1))
                .stroke(
                    warning ? Color.red : ringColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(centerTitle)
                    .font(MacSweepTheme.metricFont(size: 26))
                Text(centerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 168, height: 168)
    }
}

struct CategoryBarRow: View {
    let category: CleanupCategory
    let itemCount: Int
    let bytes: Int64
    let maxBytes: Int64

    private var fraction: Double {
        guard maxBytes > 0 else { return 0 }
        return Double(bytes) / Double(maxBytes)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: category.symbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(category.color)
                .frame(width: 32, height: 32)
                .background(category.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(category.title)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(MacSweepFormatting.bytes(bytes))
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                    Text("· \(itemCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(nsColor: .separatorColor).opacity(0.2))
                        Capsule()
                            .fill(category.color.opacity(0.75))
                            .frame(width: max(geo.size.width * fraction, 4))
                    }
                }
                .frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct MacSweepPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(MacSweepTheme.accent.opacity(configuration.isPressed ? 0.75 : 1), in: Capsule())
            .foregroundStyle(.white)
    }
}

struct MacSweepSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(configuration.isPressed ? 0.6 : 1), in: Capsule())
            .overlay(Capsule().stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5))
    }
}
