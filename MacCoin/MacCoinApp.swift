import SwiftUI

@main
struct MacCoinApp: App {
    @StateObject private var binanceService = BinanceService()
    @StateObject private var updateChecker = UpdateChecker()
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra {
            if binanceService.price != nil {
                Text("BTC/USDT: \(binanceService.formattedPrice)")
            } else if let error = binanceService.errorMessage {
                Text("오류: \(error)")
            } else {
                Text("로딩 중...")
            }

            Divider()

            Button("새로고침") {
                Task { await binanceService.fetchPrice() }
            }
            .keyboardShortcut("r")

            Button("설정...") {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }
            .keyboardShortcut(",")

            Divider()

            if updateChecker.isUpdateAvailable, let latest = updateChecker.latestVersion {
                Button("버전 \(updateChecker.currentVersion) → \(latest) 업데이트") {
                    updateChecker.openDownloadPage()
                }
            } else {
                Text("버전 \(updateChecker.currentVersion)")
                    .foregroundStyle(.secondary)
            }

            Button("종료") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Text(binanceService.menuBarTitle)
        }

        Settings {
            SettingsView(binanceService: binanceService)
        }
    }
}
