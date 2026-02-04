import SwiftUI

@main
struct MacCoinApp: App {
    @StateObject private var binanceService = BinanceService()
    @StateObject private var updateChecker = UpdateChecker()
    @Environment(\.openSettings) private var openSettings

    private var sortedSelectedCoins: [CoinSymbol] {
        CoinSymbol.allCases.filter { binanceService.selectedCoins.contains($0) }
    }

    var body: some Scene {
        MenuBarExtra {
            if let error = binanceService.errorMessage {
                Text("오류: \(error)")
            } else if binanceService.prices.isEmpty {
                Text("로딩 중...")
            } else {
                ForEach(sortedSelectedCoins) { coin in
                    if let price = binanceService.prices[coin] {
                        Text("\(coin.displayName): \(BinanceService.formattedPrice(for: coin, price: price))")
                    }
                }
            }

            Divider()

            Button("새로고침") {
                Task { await binanceService.fetchPrices() }
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
