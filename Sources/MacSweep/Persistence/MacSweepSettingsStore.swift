import Foundation

enum MacSweepSettingsStore {
    private static let key = "MacSweep.MacSweepScannerSettings"

    static func load() -> MacSweepScannerSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(MacSweepScannerSettings.self, from: data) else {
            return .defaults
        }
        return settings
    }

    static func save(_ settings: MacSweepScannerSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
