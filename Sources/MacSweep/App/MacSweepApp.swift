import SwiftUI

@main
struct MacSweepApp: App {
    @StateObject private var model = MacSweepAppModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MacSweepContentView()
                .environmentObject(model)
                .frame(minWidth: 1_040, minHeight: 680)
                .onDisappear {
                    NSApplication.shared.terminate(nil)
                }
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            MacSweepSettingsView()
                .environmentObject(model)
                .frame(width: 620, height: 590)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
