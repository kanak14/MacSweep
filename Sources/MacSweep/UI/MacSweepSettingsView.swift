import SwiftUI
import AppKit

struct MacSweepSettingsView: View {
    @EnvironmentObject private var model: MacSweepAppModel

    var body: some View {
        Form {
            Section {
                SectionHeader(
                    title: "Scan preferences",
                    subtitle: "Control which folders and categories MacSweep analyzes."
                )
                .padding(.vertical, 4)
            }

            Section("Scan folders") {
                ForEach(model.settings.scanRoots, id: \.self) { url in
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(MacSweepTheme.accent)
                        Text(url.path).lineLimit(1).truncationMode(.middle)
                        Spacer()
                        Button(role: .destructive) {
                            model.removeScanFolder(url)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button {
                    chooseFolder()
                } label: {
                    Label("Add folder…", systemImage: "plus")
                }
                Text("Downloads is included by default. Add folders explicitly to scan beyond that scope.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Old and large files") {
                Stepper(value: oldDaysBinding, in: 30...1_825, step: 30) {
                    LabeledContent("Consider unused after", value: "\(model.settings.oldFileDays) days")
                }
                Picker("Minimum large-file size", selection: minimumFileBinding) {
                    Text("100 MB").tag(Int64(100 * 1_024 * 1_024))
                    Text("250 MB").tag(Int64(250 * 1_024 * 1_024))
                    Text("500 MB").tag(Int64(500 * 1_024 * 1_024))
                    Text("1 GB").tag(Int64(1_024 * 1_024 * 1_024))
                }
                Picker("Minimum cache size", selection: minimumCacheBinding) {
                    Text("50 MB").tag(Int64(50 * 1_024 * 1_024))
                    Text("100 MB").tag(Int64(100 * 1_024 * 1_024))
                    Text("250 MB").tag(Int64(250 * 1_024 * 1_024))
                    Text("500 MB").tag(Int64(500 * 1_024 * 1_024))
                }
            }

            Section("Categories") {
                Toggle("Large application caches", isOn: settingBinding(\.includeGeneralCaches))
                Toggle("Review Trash contents", isOn: settingBinding(\.includeTrash))
                Toggle("Review iPhone and iPad backups", isOn: settingBinding(\.includeDeviceBackups))
                Toggle("Keep only the latest simulator minor per major", isOn: settingBinding(\.keepLatestSimulatorMinorPerMajor))
                Toggle("Experimental application-leftover detection", isOn: settingBinding(\.includeAppLeftovers))
                Text("Leftover suggestions are never preselected and are marked as potentially irreplaceable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Full Disk Access")
                        Text("Protected folders may be skipped. MacSweep reports any areas it cannot read.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Open System Settings") { model.openFullDiskAccessSettings() }
                        .buttonStyle(MacSweepSecondaryButtonStyle())
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button("Save and rescan") {
                        Task { await model.scan() }
                    }
                    .buttonStyle(MacSweepPrimaryButtonStyle())
                }
            }
        }
        .formStyle(.grouped)
        .padding(.top, 10)
        .navigationTitle("Settings")
    }

    private var oldDaysBinding: Binding<Int> {
        Binding(get: { model.settings.oldFileDays }, set: { model.settings.oldFileDays = $0 })
    }

    private var minimumFileBinding: Binding<Int64> {
        Binding(get: { model.settings.minimumLargeFileBytes }, set: { model.settings.minimumLargeFileBytes = $0 })
    }

    private var minimumCacheBinding: Binding<Int64> {
        Binding(get: { model.settings.minimumCacheBytes }, set: { model.settings.minimumCacheBytes = $0 })
    }

    private func settingBinding(_ keyPath: WritableKeyPath<MacSweepScannerSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { model.settings[keyPath: keyPath] = $0 }
        )
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Add to Scan"
        if panel.runModal() == .OK {
            panel.urls.forEach(model.addScanFolder)
        }
    }
}
